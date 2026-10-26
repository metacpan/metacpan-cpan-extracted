use v5.10;

package Perl::Version::Bumper;
$Perl::Version::Bumper::VERSION = '0.277';

use strict;
use warnings;
use version;

use Path::Tiny ();
use PPI::Document;
use PPI::Token::Operator;
use PPI::Token::Attribute;
use Carp qw( carp croak );

use Perl::Version::Bumper::Helper::Version qw(
    version_fmt
    version_use
    stable_version
    stable_version_dec
);

# CLASS METHODS

my $feature_version;

sub feature_version { $feature_version }

# reconstruct everything we know about every feature
# from the $DATA variable defined at the end of the file
my $FEATURE_DATA;

sub feature_data {
    my %feature;
    for ( grep !/\A(?:=|\z)/, split /\n/, $FEATURE_DATA ) {
        if (/\A *([1-9][0-9.]*)/) {    # header line
            $feature_version = version_fmt($1);
            next;
        }
        my $feature  = substr $_, 0, 33, '';    # %32s
        my $known    = substr $_, 0, 9,  '';    # %-8s
        my $enabled  = substr $_, 0, 9,  '';    # %-8s
        my $disabled = substr $_, 0, 9,  '';    # %-8s
        my $removed  = substr $_, 0, 9,  '';    # %-8s
        my @compat   = split ' ';               # %s
        y/ //d for $feature, $known, $enabled, $disabled, $removed;
        $feature{$feature}{known}     = $known;
        $feature{$feature}{enabled}   = $enabled  if $enabled;
        $feature{$feature}{disabled}  = $disabled if $disabled;
        $feature{$feature}{removed}   = $removed  if $removed;
        $feature{$feature}{compat}    = {@compat} if @compat;
        $feature{$feature}{unfeature} = 1         if $disabled;
    }
    return \%feature;
}

my %feature = %{ feature_data() };

# CONSTRUCTOR

sub _feature_in_bundle {
    my $version_num = shift;
    return {
        known => {
            map +( $_ => $feature{$_}{known} ),
            grep exists $feature{$_}{known} && $version_num >= $feature{$_}{known},
            keys %feature
        },
        enabled => {
            map +( $_ => $feature{$_}{enabled} ),
            grep !exists $feature{$_}{disabled} || $version_num < $feature{$_}{disabled},
            grep  exists $feature{$_}{enabled}  && $version_num >= $feature{$_}{enabled},
            keys %feature
        },
        disabled => {
            map +( $_ => $feature{$_}{disabled} ),
            grep exists $feature{$_}{disabled} && $version_num >= $feature{$_}{disabled},
            keys %feature
        },
    };
}

sub new {

    # stolen from Moo::Object
    my $class = shift;
    my $args = scalar @_ == 1
      ? ref $_[0] eq 'HASH'
        ? { %{ $_[0] } }
        : Carp::croak("Single parameters to new() must be a HASH ref"
            . " data => ". $_[0])
      : @_ % 2
        ? Carp::croak("The new() method for $class expects a hash reference or a"
            . " key/value list. You passed an odd number of arguments")
        : {@_}
    ;

    # handle the version attribute
    my $version_arg = $args->{version} // stable_version($]);
    my $version_num = version_fmt( $version_arg );
    croak "Unsupported Perl version: $version_arg (greater than $feature_version)"
      if $version_num > $feature_version;
    croak "$args->{version} is not a stable Perl version"
      if $version_num ne stable_version($version_num);

    return bless {
        version           => version_use($version_num),
        version_num       => $version_num,
        feature_in_bundle => _feature_in_bundle($version_num),
    }, $class;
};

# ATTRIBUTES

sub version { shift->{version} }

sub version_num { shift->{version_num} }

# PRIVATE FUNCTIONS

sub __evaluate {
    map ref()
      ? $_->[0] eq 'CODE'
          ? sub { }    # leave anonymous subs as is
          : $_->[0] eq '[' ? [ __SUB__->( @$_[ 1 .. $#$_ ] ) ]    # ARRAY
        : $_->[0] eq '{' ? { __SUB__->( @$_[ 1 .. $#$_ ] ) }      # HASH
        : __SUB__->( @$_[ 1 .. $#$_ ] )    # LIST (flattened)
      : $_,                                # SCALAR
      @_;
}

# given a list of PPI tokens, construct a Perl data structure
sub _ppi_list_to_perl_list {

    # are there constants we ought to know about?
    my $constants = ref $_[-1] eq 'HASH' ? pop @_ : {};

    # make sure we have tokens (i.e. deconstruct Statement and Structure objects)
    my @tokens = grep $_->significant, map $_->tokens, @_;
    my @stack  = my $root = my $ptr = [];
    my $prev;
    while ( my $token = shift @tokens ) {
        if ( $token->isa('PPI::Token::Structure') ) {
            if ( $token =~ /\A[[{(]\z/ ) {    # opening
                $ptr = $token eq '{' && $prev && $prev eq 'sub'    # sub { ... }
                  ? do { pop @{ $stack[-1] }; ['CODE'] }    # drop 'sub' token
                  : ["$token"];
                push @{ $stack[-1] }, $ptr;
                push @stack,          $ptr;
            }
            elsif ( $token =~ /\A[]})]\z/ ) {                      # closing
                pop @stack;
                $ptr = $stack[-1];
            }
        }
        elsif ( $token eq ',' || $token eq '=>' ) { }              # skip
        elsif ( $token->isa('PPI::Token::Symbol') ) {              # variable

            # construct the expression back (and keep the object around)
            my $expr = PPI::Document->new( \join '', $token, @tokens );

            # PPI::Document -> PPI::Statement
            # -> PPI::Token::Symbol (ignored), PPI::Sructure::Subscript (maybe)
            my ( undef, $subscript ) = $expr->child(0)->children;
            if ( $subscript && $subscript->isa('PPI::Structure::Subscript') ) {
                shift @tokens for $subscript->tokens;    # drop subcript tokens
                push @$ptr, "$token$subscript";          # symbol + subscript
            }
            else {
                push @$ptr, "$token";                    # simple symbol
            }
        }
        elsif ($token->isa('PPI::Token::Word')                     # undef
            && $token eq 'undef'
            && ( $tokens[0] ? $tokens[0] ne '=>' : !!1 ) )
        {
            push @$ptr, undef;
        }
        elsif ($token->isa('PPI::Token::HereDoc') ) {              # heredoc
            push @$ptr, join '', $token->heredoc;
        }
        else {
            my $next_sibling = $token->snext_sibling;
            push @$ptr,

              # maybe a known constant?
                exists $constants->{$token} && ( $next_sibling ? $next_sibling ne '=>' : !!1 )
                                        ? $constants->{$token}

              # various types of strings
              : $token->can('literal')  ? $token->literal
              : $token->can('simplify') ? do {
                  my $clone = $token->clone;
                  $clone->simplify && $clone->can('literal')
                                        ? $clone->literal
                                        : "$clone";
                }
              : $token->can('string')   ? $token->string

              # stop at the first operator
              : $token->isa( 'PPI::Token::Operator' ) ? last

              # give up and just stringify
              :                         "$token";
        }
        $prev = $token;
    }
    return __evaluate(@$root);
}

sub _drop_statement {
    my ( $stmt, $keep_comments ) = @_;

    # remove non-significant elements before the statement
    while ( my $prev_sibling = $stmt->previous_sibling ) {
        last if $prev_sibling->significant;
        last if $prev_sibling =~ /\n\z/;
        $prev_sibling->remove;
    }

    # remove non-significant elements after the statement
    # if there was no significant element before it on the same line
    # (i.e. it was the only statement on the line)
    $stmt->document->index_locations;
    if (  !$stmt->sprevious_sibling
        || $stmt->sprevious_sibling->location->[0] ne $stmt->location->[0] )
    {

        # collect non-significant elements until next newline (included)
        my ( $next, @to_drop ) = ($stmt);
        while ( $next = $next->next_sibling ) {
            if ( $next->significant ) {    # might be a compound statement
                for my $child ( $next->children ) {
                    last if $child->significant;
                    push @to_drop, $child;
                    last if $child =~ /\n\z/;
                }
                last;
            }
            push @to_drop, $next;
            last if $next =~ /\n\z/;
        }

        # do not drop comments if asked to keep them
        @to_drop = grep !$_->isa('PPI::Token::Comment') && $_ ne "\n", @to_drop
          if $keep_comments && grep $_->isa('PPI::Token::Comment'), @to_drop;
        $_->remove for @to_drop;

        $stmt->document->flush_locations;
    }

    # and finally remove it
    $stmt->remove;
}

sub _drop_bare {
   my ( $type, $module, $doc ) = @_;
    my $use_module = $doc->find(
        sub {
            my ( $root, $elem ) = @_;
            return !!1
              if $elem->isa('PPI::Statement::Include')
              && $elem->module eq $module
              && $elem->type eq $type
              && !$elem->arguments;    # bare use module
            return;                    # only top-level
        }
    );
    if ( ref $use_module ) {
        _drop_statement($_) for @$use_module;
    }
    return;
}

sub _find_include {
   my ( $module, $doc, $type ) = @_;
    my $found = $doc->find(
        sub {
            my ( $root, $elem ) = @_;
            return !!1
              if $elem->isa('PPI::Statement::Include')
              && $elem->module eq $module;
            return !!0;
        }
    );
    croak "Bad condition for PPI::Node->find"
      unless defined $found;    # error
    return unless $found;       # nothing found
    return $type ? grep $_->type eq $type, @$found : @$found;
}

sub _version_stmts {
   my ($doc) = @_;
    my $version_stmts = $doc->find(
        sub {
            my ( $root, $elem ) = @_;
            return !!1 if $elem->isa('PPI::Statement::Include') && $elem->version;
            return !!0;
        }
    );
    croak "Bad condition for PPI::Node->find"
      unless defined $version_stmts;
    return $version_stmts ? @$version_stmts : ();
}

use constant {
    ENABLED  => 'enabled',
    DISABLED => 'disabled',
};

use Hash::Util::FieldHash;
Hash::Util::FieldHash::fieldhash my %feature_by_scope;
my %feature_votes;
$feature_votes{+ENABLED} = {};
$feature_votes{+DISABLED} = {};
Hash::Util::FieldHash::fieldhashes values %feature_votes;

# keep track of features explicitly enabled/disabled in each scope
# this is keyed by scope and feature, and the value is status and statement
sub _add_feature_to_scope {
    my ( $elem, $feature, $status ) = @_;
    croak "Invalid status value: '$status'"
      if $status ne ENABLED && $status ne DISABLED;
    my $scope = $elem;
    while ( $scope->parent ) {    # stop at the document root
        $scope = $scope->parent;
        last if $scope->isa('PPI::Structure::Block');
    }
    $feature_by_scope{$scope}{$feature} = [ $status, $elem ];
}

# return the status of the feature for the scope surrounding the element
# the value is one of: ENABLED, DISABLED, '' (the first two are constants)
sub _feature_status_in_scope {
    my ( $feature, $elem ) = @_;
    my $scope = $elem->parent;
    my $status;
    while ( $scope ) {
        $status = $feature_by_scope{$scope}{$feature}[0]
          and last;
        $scope = $scope->parent;
    }
    return $status // '';
}

# return the stack of [ status, stmt ] up to the document root
# of all scopes where the feature is enabled or disabled
sub _feature_status_stack {
    my ( $feature, $elem ) = @_;
    my @stack;
    my $scope = ( $elem->parent );
    while ($scope) {
        if ( my $status = $feature_by_scope{$scope}{$feature}[0] ) {
            push @stack, [ $status, $feature_by_scope{$scope}{$feature}[1] ];
        }
        elsif ( !$scope->parent && !$status ) {    # document root
            push @stack, [ '', $feature_by_scope{$scope}{$feature}[1] ];
            last;
        }
        $scope = $scope->parent;
    }
    return @stack;
}

# replace a given PPI statement with the given code string
# (if the code is undef, just remove the statement entirely)
sub _replace_stmt {
    my ( $old_stmt, $new_code, $keep_comments ) = @_;
    if ( defined $new_code ) {
        my $new_stmt = PPI::Document->new( \$new_code );
        $old_stmt->insert_before( $_->remove ) for $new_stmt->elements;
        $old_stmt->remove;
    }
    else { _drop_statement( $old_stmt, $keep_comments ); }
}

my %feature_shine = (
    when_enabled => {

        # the 'bitwise' feature may break bitwise operators,
        # so disable it when bitwise operators are detected
        bitwise => sub {
            my ($doc) = @_;

            # in the following code:
            # - "safe ops" are the ones (binary and dotted binary) that
            #   depend on the 'bitwise' feature being enabled, and for whom
            #   an explicit enablement can be removed (because `use VERSION`
            #   enables it globally)
            # - "unsafe ops" are the regular binary ops that worked with
            #   'bitwise' disabled (explicitly or not), and can't have it
            #   enabled (or not disabled), for fear of breaking
            # (dotted bitwise operators are detected by PPI >= 1.285)
            my $bitwise_ops = $doc->find(
                sub {
                    my ( $root, $elem ) = @_;
                    $elem->isa('PPI::Token::Operator')
                      && $elem =~ /\A[&|~^]=?\z/;
                }
            );
            return unless $bitwise_ops;

            # binary ops are safe when 'bitwise' is explicitly enabled,
            # because they behave as expected, and unsafe it 'bitwise'
            # wasn't explicitly disabled, because they're expected to
            # have the old (before 'bitwise') behaviour
            my ( @safe_ops, @unsafe_ops );
            for my $op (@$bitwise_ops) {
                my $status = _feature_status_in_scope( bitwise => $op );
                if    ( $status eq ENABLED )  { push @safe_ops,   $op; }
                elsif ( $status ne DISABLED ) { push @unsafe_ops, $op; }
            }

            # add dotted bitwise ops to the safe ops list,
            # when under an explicitly enabled 'bitwise'
            my $dotted_bitwise_ops = $doc->find(
                sub {
                    my ( $root, $elem ) = @_;
                    $elem->isa('PPI::Token::Operator')
                      && $elem =~ /\A[&|~^]\.=?\z/;
                }
            );
            push @safe_ops,
              grep _feature_status_in_scope( bitwise => $_ ) eq ENABLED,
              @$dotted_bitwise_ops
              if $dotted_bitwise_ops;

            # safe ops: lnd the explicit `use feature 'bitwise'`
            # in the enclosing scope and vote to remove it
            for my $safe_op (@safe_ops) {
                my @status_stack = _feature_status_stack( bitwise => $safe_op );
                my $vote = $feature_votes{ +ENABLED }{ $status_stack[0][1] }{bitwise};

                # by construction, the first scope in the stack is ENABLED
                if ( @status_stack > 1 && $status_stack[1][0] eq DISABLED ) {
                    $vote->[1]++;    # vote to keep
                }
                else {
                    $vote->[0]++;    # vote to delete
                }
            }

            # if there are no unsafe ops, we're done
            return unless @unsafe_ops;

            # the `use VERSION` inserted earlier is always the first in the doc
            my $insert_point = ( _version_stmts($doc) )[0];
            my $indent = $insert_point->previous_sibling
              && $insert_point->previous_sibling->isa('PPI::Token::Whitespace')
              ? $insert_point->previous_sibling
              : '';
            my $no_feature_bitwise =
              PPI::Document->new( \"no feature 'bitwise';\n" );
            $insert_point->insert_after( $_->remove )
              for $no_feature_bitwise->elements;

            # also add an IMPORTANT comment to warn users
            $insert_point = $insert_point->snext_sibling;
            my $todo_comment = PPI::Document->new( \( << "TODO_COMMENT" ) );

$indent# IMPORTANT: Please double-check the use of bitwise operators
$indent# before removing the `no feature 'bitwise';` line below.
$indent# See manual pages 'feature' (section "The 'bitwise' feature")
$indent# and 'perlop' (section "Bitwise String Operators") for details.
TODO_COMMENT
            $insert_point->insert_before( $_->remove )
              for $todo_comment->elements;
            $insert_point->insert_before( $indent->clone ) if $indent;
        },

        # the 'signatures' feature needs prototypes to be updated.
        signatures => sub {
            my ($doc) = @_;

            # find all subs with prototypes
            my $prototypes = $doc->find('PPI::Token::Prototype');
            return unless $prototypes;

            # and turn them into prototype attributes
            for my $proto (@$prototypes) {
                next
                  if _feature_status_in_scope( signatures => $proto ) eq
                  DISABLED;
                $proto->insert_before( PPI::Token::Operator->new(':') );
                $proto->insert_before(
                    PPI::Token::Attribute->new("prototype$proto") );
                $proto->remove;
            }
        },

        # the 'fc' feature means CORE::fc is not required
        fc => sub {
            my ($doc) = @_;

            # find all occurences of 'CORE::fc'
            my $core_fc = $doc->find(
                sub {
                    my ( $root, $elem ) = @_;
                    return !!1
                      if $elem->isa('PPI::Token::Word') && $elem eq 'CORE::fc';
                    return !!0;
                }
            );
            return unless $core_fc;

            # and replace them by 'fc'
            # (only when not in scope of a `no feature 'fc'`)
            $_->replace( PPI::Token::Word->new('fc') )
              for grep _feature_status_in_scope( fc => $_ ) ne DISABLED,
              @$core_fc;
        },
    },

    when_disabled => {

        # disabling the 'apostrophe_as_package_separator' feature
        # drops support for apostrophe in package names
        apostrophe_as_package_separator => sub {
            my ($doc) = @_;

            # find all names with an apostrophe
            my $apostrophes = $doc->find(
                sub {
                    my ( $root, $elem ) = @_;
                    $elem->isa('PPI::Token::Word') && $elem =~ /'/;
                }
            );
            return unless $apostrophes;

            # and replace it with double colons
            for my $word (@$apostrophes) {
                next
                  if ENABLED eq _feature_status_in_scope(
                    apostrophe_as_package_separator => $word );
                ( my $colon = "$word" ) =~ s/'/::/g;
                $word->replace( bless { content => $colon },
                    'PPI::Token::Word' );
            }
        },
    },

);

# PRIVATE "METHODS"

# handle the case of CPAN modules that serve as compatibility layer for some
# features on older Perls, or that existed before the feature was developed
sub _handle_compat_modules {
    my ( $self, $doc ) = @_;
    my $feature_in_bundle = $self->{feature_in_bundle};
    for my $feature ( grep exists $feature{$_}{compat}, keys %feature ) {
        for my $compat ( keys %{ $feature{$feature}{compat} } ) {
            for my $include_compat ( _find_include( $compat => $doc ) ) {

                # handle `no $compat;`
                if ( $include_compat->type eq 'no' ) {

                    # if the feature is known and not disabled
                    # and the compat module has an unimport() sub
                    if (   exists $feature_in_bundle->{known}{$feature}
                        && !exists $feature_in_bundle->{disabled}{$feature}
                        && $feature{$feature}{compat}{$compat} <= 0 )
                    {
                        my $no_feature = # feature enabled, and not disabled yet
                          PPI::Document->new( \"no feature '$feature';\n" );
                        $include_compat->insert_after( $_->remove )
                          for $no_feature->elements;
                    }

                    # some compat modules have no unimport() sub
                    # so we drop the useless `no $compat`
                    _drop_statement($include_compat)
                      if exists $feature_in_bundle->{known}{$feature}
                      || $feature{$feature}{compat}{$compat} > 0;
                }

                # handle `use $compat;`
                if ( $include_compat->type eq 'use' ) {
                    my $drop_stmt;    # should we drop the old statement?

                    # if the feature is known and not enabled or an unfeature
                    # and the compat module has an import() sub
                    if (   exists $feature_in_bundle->{known}{$feature}
                        && (  !exists $feature_in_bundle->{enabled}{$feature}
                            || exists $feature{$feature}{unfeature} )
                        && $feature{$feature}{compat}{$compat} >= 0 )
                    {
                        my $use_feature =
                          PPI::Document->new( \"use feature '$feature';\n" );
                        $include_compat->insert_after( $_->remove )
                          for $use_feature->elements;
                        $drop_stmt++;    # it's been replaced
                    }

                    # backward compatibility features, like 'indirect',
                    # can be enabled before being known
                    # (also handle the unlikely case where there's no import())
                    $drop_stmt++
                      if !exists $feature{$feature}{unfeature}
                      && ( exists $feature_in_bundle->{enabled}{$feature}
                        || $feature{$feature}{compat}{$compat} < 0 );

                    _drop_statement($include_compat) if $drop_stmt;
                }
            }
        }
    }
}

# given $old and $new lists ($new is a subset of $old)
# return the items that are in $old and not in $new
sub _missing_items {
    my ($old, $new) = @_;
    my %to_remove;
    $to_remove{$_}++ for @$old;
    $to_remove{$_}-- for @$new;
    return grep $to_remove{$_} > 0, keys %to_remove;
}

# return $old without any of the $to_remove items
sub _remove_items {
    my ( $old, $to_remove ) = @_;
    my %to_remove;
    @to_remove{@$to_remove} = ();
    return grep !exists $to_remove{$_}, @$old;
}

sub _cleanup_bundled_features {
    my ( $self, $doc, $old_num ) = @_;
    my $version_num       = $self->version_num;
    my $feature_in_bundle = $self->{feature_in_bundle};

    # `use feature` and `no feature` are "feature controllers" (or switches),
    # that are used to enable or disable the feature in the current lexical
    # scope.
    #
    # For every controller, there are several times when we can decide
    # to remove a feature or not from the argument list of the controller
    # statement.
    #
    # The decision is taken via a "vote": at different times in the
    # algorithm a vote to remove or keep will be cast.  In the end,
    # a specific feature will be removed from a specific controller
    # statement when there are no keep votes and at least on remove vote.
    #
    # The votes are collected in the %feature_votes hash, which is keyed
    # by the type of statement: ENABLED (use) or DISABLED (no).
    # One level down, a FieldHash uses the actual PPI statement as the
    # key and the values are the features.
    #
    # The list of original arguments is stored in the special '' key.

    for my $module (qw( feature experimental )) {

        # drop features enabled by this bundle
        # (also if they were enabled with `use experimental`)
        for my $stmt ( _find_include( $module => $doc, 'use' ) ) {
            my @old_args = @{ $feature_votes{ +ENABLED }{$stmt}{''} };
            my @new_args =    # keep enabling features that
              grep !
              exists $feature_in_bundle->{enabled}{$_}    # are not enabled yet
              || exists $feature{$_}{unfeature},          # or are unfeatures
              grep exists $feature{$_},                   # and actually exist
              @old_args;
            next if @new_args == @old_args;               # nothing to change
            $feature_votes{ +ENABLED }{$stmt}{$_}[0]++    # vote to delete
              for _missing_items( \@old_args, \@new_args );
        }

        # drop disabled features that are disabled by this bundle
        # (also if they were disabled with `no experimental`)
        for my $stmt ( _find_include( $module => $doc, 'no' ) ) {
            my @old_args = @{ $feature_votes{ +DISABLED }{$stmt}{''} };
            my @new_args =                # keep disabling features
              grep exists $feature{$_}    # that actually exist and are
              && !exists $feature_in_bundle->{disabled}{$_},  # not disabled yet
              @old_args;
            next if @new_args == @old_args;                # nothing to change
            $feature_votes{ +DISABLED }{$stmt}{$_}[0]++    # vote to delete
              for _missing_items( \@old_args, \@new_args );
        }
    }

    # deal with compat modules
    $self->_handle_compat_modules($doc);

    # apply some feature shine when crossing the feature enablement boundary
    for my $feature ( sort keys %{ $feature_shine{when_enabled} }  ) {
        my $feature_enabled = $feature{$feature}{enabled};
        $feature_shine{when_enabled}{$feature}->($doc)
          if $old_num < $feature_enabled         # code from before the feature
          && $version_num >= $feature_enabled;   # bumped to after the feature
    }

    # apply some feature shine when crossing the feature disablement boundary
    for my $feature ( sort keys %{ $feature_shine{when_disabled} }  ) {
        my $feature_disabled = $feature{$feature}{disabled};
        $feature_shine{when_disabled}{$feature}->($doc)
          if $old_num < $feature_disabled        # code from before the feature
          && $version_num >= $feature_disabled;  # bumped to after the feature
    }

    # drop experimental warnings, if any
    for my $warn_line ( _find_include( warnings => $doc, 'no' ) ) {
        my @old_args = _ppi_list_to_perl_list( $warn_line->arguments );
        next unless grep /\Aexperimental::/, @old_args;
        my @new_args = grep {
            ( my $feature = $_ ) =~ s/\Aexperimental:://;
            !exists $feature_in_bundle->{enabled}{$feature};
          }
          grep /\Aexperimental::/, @old_args;
        my @keep_args = grep !/\Aexperimental::/, @old_args;
        next if @new_args == @old_args    # nothing to remove
          || @new_args + @keep_args == @old_args;
        _replace_stmt(
            $warn_line,
            @new_args || @keep_args    # replace old statement
            ? "no warnings @{[ join ', ', map qq{'$_'}, @new_args, @keep_args]};"
            : undef                    # or delete it entirely
        );
    }

    # update statements according to the result of the vote
    for my $status ( ENABLED, DISABLED ) {
        for my $stmt (
            map Hash::Util::FieldHash::id_2obj($_),
            keys %{ $feature_votes{$status} }
          )
        {
            my @remove;
            my $votes = $feature_votes{$status}{$stmt};

	    # check all features controlled by that statement
            for my $feature ( grep $_, keys %$votes ) {
                next
                  if !$votes->{$feature}[0]    # no deletion vote
                  || $votes->{$feature}[1];    # at least one keep vote
                push @remove, $feature;
            }
            if (@remove) {
                my $verb     = $status eq ENABLED ? 'use' : 'no';
                my $module   = $stmt->module;
                my $features = join ', ', map qq{'$_'},
                  _remove_items( $feature_votes{$status}{$stmt}{''}, \@remove );
                _replace_stmt( $stmt,
                    $features ? "$verb $module $features;" : undef );
            }
        }
    }

    # strict is automatically enabled with 5.12
    _drop_bare( use => strict => $doc ) if $version_num >= 5.012;

    # warnings are automatically enabled with 5.36
    _drop_bare( use => warnings => $doc ) if $version_num >= 5.036;

    return;
}

sub _insert_version_stmt {
    my ( $self, $doc, $old_num ) = @_;
    $old_num //= 5.008;
    my $version_stmt =
      PPI::Document->new( \sprintf "use %s;\n", $self->version );
    my $insert_point = $doc->schild(0) // $doc->child(0);
    return unless defined $insert_point;    # empty document

    # record the indent before the next significant sibling
    # (unless it's a version statement: it will be removed,
    # and this version statement will replace it)
    my $indent;
    $indent = $insert_point->previous_sibling
      if $insert_point->previous_sibling
      && $insert_point->previous_sibling->isa('PPI::Token::Whitespace')
      && !($insert_point->isa('PPI::Statement::Include') && $insert_point->version );

    # record individual features being enabled/disabled
    for my $module (qw( feature experimental )) {
        for my $use_feature ( _find_include( $module => $doc, 'use' ) ) {
            my @old_args = _ppi_list_to_perl_list( $use_feature->arguments );
            _add_feature_to_scope( $use_feature, $_, ENABLED ) for @old_args;
            $feature_votes{+ENABLED}{$use_feature}{''} = \@old_args;
        }
        for my $no_feature ( _find_include( $module => $doc, 'no' ) ) {
            my @old_args = _ppi_list_to_perl_list( $no_feature->arguments );
            _add_feature_to_scope( $no_feature, $_, DISABLED ) for @old_args;
            $feature_votes{+DISABLED}{$no_feature}{''} = \@old_args;
        }
    }

    # put the use VERSION LINE at the top of the file
    if ( $insert_point->significant ) {
        $insert_point->insert_before( $_->remove ) for $version_stmt->elements;
        $insert_point->insert_before( $indent->clone ) if $indent;
    }
    else {
        $doc->add_element( $_->remove ) for $version_stmt->elements;
    }

    # cleanup features enabled or disabled by the new version
    _cleanup_bundled_features( $self, $doc, $old_num );
}

sub _try_compile_file {
    my ( $file, $env ) = @_;
    $env //= {};

    # redirect STDERR for quietness
    my $tmperr = Path::Tiny->tempfile;
    open( \*OLDERR, '>&', \*STDERR ) or die "Can't dup STDERR: $!";
    open( \*STDERR, '>',  $tmperr )  or die "Can't re-open STDERR: $!";

    # setup a local environment
    local %ENV = %ENV;
    $ENV{$_} = $env->{$_} for keys %$env;

    # try to compile the file
    my $status = system $^X, '-c', $file;
    my $exit = $status >> 8;

    # get STDERR back, and warn about errors while compiling
    open( \*STDERR, '>&', \*OLDERR ) or die "Can't restore STDERR: $!";
    warn $tmperr->slurp if $exit;

    return !$exit;    # 0 means success
}

# PUBLIC METHOS

sub bump_ppi {
    my ( $self, $doc ) = @_;
    $doc = $doc->clone;
    my $source = $doc->filename // 'input code';

    # found at least one version statement
    if ( my @version_stmts = _version_stmts($doc) ) {

        # bail out if there's more than one `use VERSION`
        if ( @version_stmts > 1 ) {
            carp "Found multiple use VERSION statements in $source:"
              . join ', ', map $_->version, @version_stmts;
        }

        # drop the existing version statement
        # and add the new one at the top
        else {
            my ($use_v) = _version_stmts($doc);    # there's only one
            my $old_num = version::->parse( $use_v->version )->numify;

            # record the features enabled and disabled by the bundle
            my $feature_in_old_bundle = _feature_in_bundle($old_num);
            _add_feature_to_scope( $use_v, $_, ENABLED )
              for keys %{ $feature_in_old_bundle->{enabled} };
            _add_feature_to_scope( $use_v, $_, DISABLED )
              for keys %{ $feature_in_old_bundle->{disabled} };

            if ( $old_num <= $self->version_num ) {
                _insert_version_stmt( $self, $doc, $old_num );
                _drop_statement( $use_v, !!1 );
            }
        }
    }

    # no version statement found, add one
    else { _insert_version_stmt( $self, $doc ); }

    return $doc;
}

sub bump {
    my ( $self, $code, $filename ) = @_;
    my $doc = PPI::Document->new( \$code, filename => $filename );
    $filename //= 'input code';
    croak "Parsing of $filename failed" unless defined $doc;
    return $self->bump_ppi($doc)->serialize;
}

sub bump_file {
    my ( $self, $file ) = @_;
    $file = Path::Tiny->new($file);    # in case it's not a Path::Tiny yet
    my $code   = $file->slurp;
    my $bumped = $self->bump( $code, $file );
    if ( $bumped ne $code ) {
        $file->append( { truncate => 1 }, $bumped );
        return !!1;
    }
    return !!0;
}

# this one is private and returns an array ref with two values:
# the new PPI::Document, and the version it was actually bumped to
sub _bump_ppi_safely {
    my ( $self, $doc, $options ) = @_;
    my $version_limit = $options->{version_limit};
    $version_limit &&= stable_version($version_limit);
    $version_limit //= do {
        my @versions = map eval { version_fmt( $_->version ) },
          _version_stmts($doc);
        $versions[0] // 5.010;
    };

    # try compiling the file: if it fails, our safeguard won't work
    my $source = $doc->filename // 'input code';
    my $tmp    = Path::Tiny->tempfile;
    $tmp->spew( $doc->serialize );
    unless ( _try_compile_file( $tmp, $options->{env} ) ) {
        warn "Can't bump Perl version safely for $source: it does not compile\n";
        return [ $doc->clone, undef ];    # undef means "didn't compile"
    }

    # try bumping down version until it compiles
    my $bumped_doc;
    my $version = $self->version_num;
    while ( $version >= $version_limit or $version = !!0 ) {
        my $perv = $self->version_num eq $version
          ? $self    # no need to create a new object
          : Perl::Version::Bumper->new( version => $version );
        $bumped_doc = $perv->bump_ppi($doc);

        # try to compile the file
        $tmp = Path::Tiny->tempfile;
        $tmp->spew( $bumped_doc->serialize );
        last if _try_compile_file( $tmp, $options->{env} );

        # bump version down and repeat
        $version = stable_version_dec($version);
    }

    return $version ? [ $bumped_doc, $version ] : [ $doc->clone, $version ];
}

sub bump_ppi_safely {
    my ( $self, $doc, $options ) = @_;
    return $self->_bump_ppi_safely( $doc, $options )->[0];
}

sub bump_safely {
    my ( $self, $code, $options ) = @_;
    my $filename = $options->{filename} // 'input code';
    my $doc      = PPI::Document->new( \$code, filename => $filename );
    croak "Parsing of $filename failed" unless defined $doc;
    return $self->_bump_ppi_safely( $doc, $options )->[0]->serialize;
}

sub bump_file_safely {
    my ( $self, $file, $options ) = @_;
    my $doc = PPI::Document->new("$file");    # stringify any object
    croak "Parsing of $file failed" unless defined $doc;
    my ( $bumped_doc, $version ) =
      @{ $self->_bump_ppi_safely( $doc, $options ) };
    Path::Tiny->new($file)->append( { truncate => 1 }, $bumped_doc->serialize )
      if $version;
    return $version;
}

1;

=pod

=head1 NAME

Perl::Version::Bumper - Update C<use VERSION> on any Perl code

=head1 SYNOPSIS

    use Perl::Version::Bumper;

    my $perv = Perl::Version::Bumper->new( version => 'v5.36' );

    # bump a PPI::Document
    my $bumped_ppi = $perv->bump_ppi($ppi_doc);

    # bump source code
    my $bumped_code = $perv->bump($code);

    # bump the source of a file
    my $success = $perv->bump_file($filename);

    # safe versions (check the result compiles)
    my $bumped_ppi  = $perv->bump_ppi_safely($ppi_doc);
    my $bumped_code = $perv->bump_safely($code);
    my $success     = $perv->bump_file_safely( $filename, $version_limit );

=head1 DESCRIPTION

C<Perl::Version::Bumper> can update Perl code to make it declare it uses
a more recent version of the Perl language by way of C<use VERSION>.

It takes care of removing unnecessary loading of L<feature> and
L<experimental> L<warnings>, and adds the C<use VERSION> line at the
top of the file (thus encouraging "line 1 semantics").

It also manages the removal of "compatibility" modules when the feature
they provide a compatibility layer with is fully supported in the target
Perl version.

If the code already declares a Perl version, it can only be bumped
to a higher version.

For more information about why you would want to use this module
(or the associated program L<perl-version-bump>), please check
L<Perl::Version::Bumper::Rationale>.

The module L<exports|/EXPORTS> a few helper functions. These are mostly used
by support tools for this distribution, and are not meant for general use.

=head1 CONSTRUCTOR

=head2 new

    my $perv = Perl::Version::Bumper->new( %attributes );
    my $perv = Perl::Version::Bumper->new( \%attributes );

Return a new C<Perl::Version::Bumper> object.

=head1 ATTRIBUTES

=head2 version

The target version to bump to.

Defaults to the stable version less than or equal to the version of the
currenly running C<perl>.

The constructor accepts both forms of Perl versions, regular
(e.g. C<v5.36>) and floating-point (e.g. C<5.036>), and will
turn them into a string suitable for C<use VERSION>.

To protect against simple mistakes (e.g. passing C<5.36> instead of
C<v5.36>), the constructor does some sanity checking, and checks that
the given version:

=over 4

=item *

is parsable as a Perl version number,

=item *

is greater than or equal to C<v5.10>,

=item *

is lower than the version of the Perl currently running,

=item *

is a stable Perl version.

=back

In case any of the above checks fail, the constructor will die.

The constructor will also silently drop any sub-version information
(so C<v5.36.2> will be turned into C<v5.36>).

=head1 CLASS METHODS

=head2 feature_version

Return the version (in numeric format) of the feature set recognized
by this module. It is not possible to bump code over that version.

The current value of C<feature_version> is: C<5.044>.

=head2 feature_data

Return a I<copy> of the internal data structure containing all the
information about features. That should only be needed for testing
and debugging.

=head1 METHODS

=head2 version_num

Return the L</version> attribute as a number.

=head2 bump_ppi

    my $bumped_ppi_doc = $perv->bump_ppi($ppi_doc);

Take a L<PPI::Document> as input, and return a I<new> L<PPI::Document>
with its declared version bumped to L</version>.

=head2 bump

    my $bumped_code = $perv->bump($code);

Take a string containing Perl code as input, bump the declared Perl
version in the source code to L</version>, and return the new source
code as a string.

=head2 bump_file

    $perv->bump_file($filename);

Bump the code of the file argument in-place.

Return a boolean indicating if the file content was modified or not.

=head1 SAFE METHODS

The L</bump_ppi>, L</bump> and L</bump_file> methods previously described
modify the source code they're given, but give I<no garanties> that the
updated code will even compile.

To address this issue, L</bump_ppi_safely>, L</bump_safely> and
L</bump_file_safely> methods work as the regular methods, but will only
produce code that actually compiles.

If all attempts fail, the return value is identical to the input value.

=head2 Example of a safe bump

The following code uses L<multidimensional array emulation|perlvar/$;>:

    my %h; $h{ 1, 2 } = 3;    # same as $foo{"1\x{1c}2"} = 3;

L</bump> will produce the following when trying to update it to C<v5.40>:

    use v5.40;
    my %h; $h{ 1, 2 } = 3;    # same as $foo{"1\x{1c}2"} = 3;

Which fails to compile with the following error:

    Multidimensional hash lookup is disabled

It's not possible to just bump this code up to C<v5.40> and expect it to
work, because it uses multidimensional array emulation, and the feature
that represents this (C<multidimensional>) was disabled in C<v5.36>.
This code will in fact fail to compile with all version bundles greater
or equal to C<v5.36>.

A I<safe way> to try to bump this code to C<v5.40> is to try with
C<v5.40>, detect it fails to compile, try again with C<v5.38> and
C<v5.36>, which also fail, until we hit C<v5.34> which compiles just
fine (because the C<multidimensional> feature is still enabled in that
bundle). Leaving us with the following code:

    use v5.34;
    my %h; $h{ 1, 2 } = 3;    # same as $foo{"1\x{1c}2"} = 3;

The code needs to be updated to I<not> use multidimensional array emulation
before it can I<safely> be bumped past version C<v5.34>.

=head2 Process of a safe bump

The process for a safe bump is to take some input, and try to compile it.
If the compilation fails, return immediately.

Otherwise, continue with the process: bump the content, and try to
compile the result. Return as soon as compilation succeeds.

If compilation fails, decrease the target Perl version number, bump
the content to that version, and try to compile the result again. Keep
decreasing the target version, all the way back to the currently
declared version in the document, or L<version_limit>, whichever is more
recent. Give up after the last compilation failure.

=head2 Options for a safe bump

All the methods below take one input argument (a L<PPI::Document>,
a string of code or a filename) and one optional hash reference
for options.

The possible options are:

=over 4

=item version_limit

The version at which to stop decreasing the target version.
Defaults to C<v5.10>.

=item env

A hash reference of key/value pairs for environment variables
to be set when trying to compile the bumped code.

=back

=head2 bump_ppi_safely

    my $bumped_ppi = $perv->bump_ppi_safely( $ppi_doc, \%options );

Safely bump the source code in the given L<PPI::Document>.

The return value is a new L<PPI::Document> containing the result of the
"safe bump" (its content might be the same as the original if there's
no safe way to bump the code).

=head2 bump_safely

    my $bumped_code = $perv->bump_safely( $code, \%options );
    my ( $bumped_code, $new_version ) = $perv->bump_safely($code);

Safely bump the source code given as a string.

The return value is a string containing the new source code.

=head2 bump_file_safely

    $perv->bump_file_safely( $filename, \%options );

Safely bump the code in the file argument in-place. The file will
not be modified if the code can't be bumped safely.

The return value is C<undef> if the original didn't compile, false
if all attempts to bump the file failed, and the actual (numerical)
version number the file was bumped to in case of success.

=head1 VERSION UPGRADE ALGORITHM

For a given version number, a feature has three attributes:

=over 4

=item known

the B<perl> I<binary> knows about the feature starting from that version.

If it's not known, passing it to C<use feature> will I<die> during
compilation with C<Feature "XXX" is not supported by Perl 5.x.y> (where
5.x.y is the version of the binary C<perl> program).

=item enabled

the feature is enabled starting with the corresponding I<feature> bundle
(i.e. C<use VERSION> will implicitely enable it).

=item disabled

the feature is disabled starting from the corresponding I<feature> bundle
(i.e. C<use VERSION> will implicitely disable it).

This is the case for so-called "unfeatures", i.e. constructs that were
deemed undesirable and removed from the language (e.g. C<indirect>,
C<bareword_filehandles>, etc.).

=item removed

the feature was removed starting from the given version.

The only feature that was removed so far is C<array_base> (in Perl v5.30).

=back

If there is more than one C<use VERSION> line in the file, the algorithm
will bail out. Otherwise, the previous C<use VERSION> line will be
removed, and a new one added at the top of the file (line 1).

The features that were enabled via C<use feature> and are part of the
C<VERSION> feature bundle will be removed from the corresponding C<use
feature> or C<use experimental> lines. The disabling of the corresponding
C<experimental> warnings will be removed.

"Unfeatures" are treated differently. Unfeatures are features that were
created to represent historical Perl behaviour, and are considered enabled
by default in all bundles until they are disabled at a later stage. If an
unfeature is enabled, it is considered to be for documentation purposes
(to indicate that the undesirable historical feature was used), and
therefore not removed, even if the specified C<VERSION> enables it.

The (un)features that were disabled via C<no feature> and are disabled
as part of the C<VERSION> feature bundle will be removed from the
corresponding C<use feature> or C<use experimental> lines.

If compatibility modules (CPAN modules that provide support for the
feature in older Perls) were loaded, they will removed if the feature
is enabled in the feature bundle for C<VERSION>, or replaced by the
corresponding C<use feature> if the feature is known by the corresponding
C<perl> binary but not yet enabled by the feature bundle. (In the context
of compatibility modules for unfeatures, the same consideration for
documentation purposes apply.)

When a feature is enabled (or disabled) in the context of a feature
version bundle that's less than the version when the feature was known
by Perl, the line won't be removed.

For example this line:

    use feature 'signatures';

will die with any perl before perl5.20.0, because the binary does not
know about the feature itself.

When writing code like this:

    use v5.10;
    use feature 'signatures';

one is opting into a version of the Perl language that is not described
by any specific feature bundle. However, any perl that knows about the
C<signatures> feature will know how to run it.

Bumping it to the feature bundle for v5.16, for example, is valid,
and will work with any B<perl> that knows about the C<signatures> feature:

    use v5.16;
    use feature 'signatures';

And so on until v5.36, when the C<signatures> feature was enabled by
the corresponding version bundle:

    use v5.36;

Finally, some features may imply extra edits:

=over 4

=item bitwise

When the C<bitwise> feature is enabled, the behaviour of the bitwise
operators (C<&>, C<|>, C<~> and C<^>) is modified. If the code makes use
of one of them, and the code is moved from a version I<before> v5.28
to a version greater or equal to v5.28, the C<bitwise> feature will
be I<disabled>, and a comment will be added, asking the maintainer to
review their use according to the C<bitwise> feature before removing it.

=item signatures

When signatures are implicitely enabled, any prototypes will be rewritten
with the prototype attribute syntax. For example:

    sub foo ($@) { ... }

will become:

    sub foo :prototype($@) { ... }

=item fc

Once C<fc> is implicitely enabled, All uses of C<CORE::fc> will be
replaced by a bare C<fc>.

=item apostrophe_as_package_separator

When the use of apostrophe (C<'>) as package separator is implicitely
disabled, every C<'> used as such will be replaced by C<::>.

=back

=head2 Feature/version data table

The following table is used to generate the feature data hash.

It is generated using the C<bin/build_feature_data.pl> script
shipped with the distribution.

The keys are:

=over 4

=item known

when perl first learnt about the feature

=item enabled

when the feature was first enabled (may be before it was known)

=item disabled

when the feature was first disabled

=item compat

replacement modules for features to be deprecated / added

=back

Different features have different lifecycles:

=over 4

=item *

New features (i.e. additional behaviour that didn't exist in Perl v5.8):

=over 4

=item *

are C<known> in the Perl release that introduced them

=item *

are C<enabled> either in the same version (e.g. C<say>, C<state>)
or after an "experimental" phase (e.g. C<signatures>, C<bitwise>)

=item *

once enabled, they are not meant to be C<disabled> in a later bundle.

=back

=item *

Unfeatures, or backwards compatibility features (features that existed
in older Perls,  but were later deemed undesirable, and scheduled for
being eventually disabled or removed):

=over 4

=item *

are C<enabled> in the C<:default> bundle (they were part of the old
Perl 5 behaviour) before they are even C<known> (a feature that
represents them was added to Perl).

=item *

are meant to be manually disabled (with C<no feature>), until a
later feature bundle eventually disables them by default.

=back

=back

"compat" modules are CPAN modules meant to add support to the feature on
perls where it's not available yet. They exist both for new features and
backwards compatibility features. The number following the module name in
the data structure below is the sum of 1 (if the module has an C<import>
method) and -1 (if the module has an C<unimport> method).

=cut

BEGIN {
    $FEATURE_DATA = << '=cut';

=pod

                  5.044 features known    enabled  disabled removed  compat
                             say   5.010    5.010                    Perl6::Say 1 Say::Compat 1
                           state   5.010    5.010
                          switch   5.010    5.010    5.036
                 unicode_strings   5.012    5.012
                      array_base   5.016    5.010    5.016    5.030
                     current_sub   5.016    5.016
                       evalbytes   5.016    5.016
                              fc   5.016    5.016
                    unicode_eval   5.016    5.016
                    lexical_subs   5.018    5.026
                       postderef   5.020    5.024
                    postderef_qq   5.020    5.024
                      signatures   5.020    5.036
                         bitwise   5.022    5.028
                     refaliasing   5.022
                   declared_refs   5.026
                        indirect   5.032    5.010    5.036           indirect 0
                             isa   5.032    5.036
                multidimensional   5.034    5.010    5.036           multidimensional 0
            bareword_filehandles   5.034    5.010    5.038           bareword::filehandles 0
                             try   5.034    5.040                    Feature::Compat::Try 1 Syntax::Feature::Try 0 Syntax::Keyword::Try 0
                           defer   5.036                             Feature::Compat::Defer 1 Syntax::Keyword::Defer 0
         extra_paired_delimiters   5.036
                     module_true   5.038    5.038
                           class   5.038                             Feature::Compat::Class 1
 apostrophe_as_package_separator   5.042    5.010    5.042
                      smartmatch   5.042    5.010    5.042
                     keyword_all   5.042
                     keyword_any   5.042
                     enhanced_xx   5.044

=cut

}

=head1 ADDITIONAL INFORMATION ABOUT PERL FEATURES AND CONSTRUCTS

=head2 Official documentation

=over 4

=item L<feature>

Perl pragma to enable new features.

=item L<perlexperiment>

A listing of experimental features in Perl.

=item L<experimental>

This pragma provides an easy and convenient way to enable or disable
experimental features.

=back

=head2 CPAN Modules

=over 4

=item L<Syntax::Construct>

For some new syntactic constructs, there is the L<feature pragma>.
For the rest, there is L<Syntax::Construct>.::

=item L<Perl::MinimumVersion>

Find a minimum required version of C<perl> for Perl code.

=item L<Perl::MinimumVersion::Fast>

L<Perl::MinimumVersion::Fast> is an alternative fast & lightweight
implementation of L<Perl::MinimumVersion>.

=back

=head2 Other

=over 4

=item L<https://sheet.shiar.nl/perl>

The most significant features introduced for recent versions of the Perl
scripting language.

=back

=head1 ACKNOWLEDGMENT

This software was originally developed at Booking.com. With approval
from Booking.com, this software was released as open source, for which
the authors would like to express their gratitude.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2024-2026 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
