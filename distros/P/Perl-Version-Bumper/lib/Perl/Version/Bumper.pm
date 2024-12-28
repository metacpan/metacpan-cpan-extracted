use v5.10;

package Perl::Version::Bumper;
$Perl::Version::Bumper::VERSION = '0.181';

use strict;
use warnings;
use version;

use Path::Tiny;
use PPI::Document;
use PPI::Token::Operator;
use PPI::Token::Attribute;
use Carp qw( carp croak );

# reconstruct everything we know about every feature from the DATA section
my ( $feature_version, %feature );
while (<DATA>) {
    chomp;
    if (/\A *([1-9][0-9.]*)/) {    # header line
        $feature_version = version_fmt($1);
        next;
    }
    my $feature  = substr $_, 0, 27, '';    # %26s
    my $known    = substr $_, 0, 9,  '';    # %-8s
    my $enabled  = substr $_, 0, 9,  '';    # %-8s
    my $disabled = substr $_, 0, 9,  '';    # %-8s
    my @compat = split ' ';                 # %s
    y/ //d for $feature, $known, $enabled, $disabled;
    $feature{$feature}{known}    = $known;
    $feature{$feature}{enabled}  = $enabled  if $enabled;
    $feature{$feature}{disabled} = $disabled if $disabled;
    $feature{$feature}{compat}   = {@compat} if @compat;
}

# EXPORTABLE FUNCTIONS

use Exporter 'import';

our @EXPORT_OK = qw(
    version_fmt
    version_use
    stable_version
    stable_version_inc
    stable_version_dec
);

# return a normalized version of a plausible Perl version number (or die)
sub version_fmt {
    my $o = shift // $];
    $o = $] unless length $o;
    my $v = version::->parse($o)->numify;    # accept everything
    return $v < 5.010
      ? croak "Unsupported Perl version: $o"
      : sprintf "%.3f", $v;                  # Perl version bundle
}

# return a normalized version, suitable for "use VERSION"
sub version_use {
    my $o = shift // $];
    $o = $] unless length $o;
    my $v = version::->parse($o)->numify;    # accept everything
    return $v < 5.010
      ? croak "Unsupported Perl version: $o"
      : sprintf 'v5.%d', substr( $v, 2, 3 );    # Perl version bundle
}

# return the closest stable version number lower than the parameter
sub stable_version {
    my $v = version_fmt(shift);
    $v *= 1000;
    return sprintf "%.3f", ( int($v) - $v % 2 ) / 1000;
}

# increment the version number to the next stable version
sub stable_version_inc {
    my $v = stable_version(shift);    # closest previous stable
    return sprintf "%.3f", $v + 0.002;
}

# decrement the version number to the previous stable version
sub stable_version_dec {
    my $v = version_fmt(shift);    # format the version
    my $s = stable_version($v);    # get the closest previous stable
    return $v ne $s
      ? $s                         # dev -> previous stable
      : sprintf "%.3f", $s - 0.002 # previous stable
}

# CLASS METHODS

sub feature_version { $feature_version }

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
      : $_,                                  # SCALAR
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
        my ( $next, @to_drop ) =  ( $stmt );
        while ( $next = $next->next_sibling ) {
            last if $next->significant;
            push @to_drop, $next;
            last if $next eq "\n";
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

my %feature_shine = (

    # the 'bitwise' feature may break bitwise operators,
    # so disable it when bitwise operators are detected
    bitwise => sub {
        my ($doc) = @_;

        # this only matters for code using bitwise ops
        return unless $doc->find(
            sub {
                my ( $root, $elem ) = @_;
                $elem->isa('PPI::Token::Operator') && $elem =~ /\A[&|~^]=?\z/;
            }
        );

        # the `use VERSION` inserted earlier is always the first one in the doc
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
        my $todo_comment =
          PPI::Document->new( \( << "TODO_COMMENT" ) );

$indent# IMPORTANT: Please double-check the use of bitwise operators
$indent# before removing the `no feature 'bitwise';` line below.
$indent# See manual pages 'feature' (section "The 'bitwise' feature")
$indent# and 'perlop' (section "Bitwise String Operators") for details.
TODO_COMMENT
        $insert_point->insert_before( $_->remove ) for $todo_comment->elements;
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
            $proto->insert_before( PPI::Token::Operator->new(':') );
            $proto->insert_before(
                PPI::Token::Attribute->new("prototype$proto") );
            $proto->remove;
        }
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

                    # if the feature is known and neither enabled nor disabled
                    # and the compat module has an import() sub
                    if (   exists $feature_in_bundle->{known}{$feature}
                        && (  !exists $feature_in_bundle->{enabled}{$feature}
                            || exists $feature_in_bundle->{disabled}{$feature} )
                        && $feature{$feature}{compat}{$compat} >= 0 )
                    {
                        my $use_feature =
                          PPI::Document->new( \"use feature '$feature';\n" );
                        $include_compat->insert_after( $_->remove )
                          for $use_feature->elements;
                    }

                    # backward compatibility features, like 'indirect',
                    # can be enabled before being known
                    # (also handle the unlikely case where there's no import())
                    _drop_statement($include_compat)
                      if exists $feature_in_bundle->{enabled}{$feature}
                      || exists $feature_in_bundle->{known}{$feature}
                      || $feature{$feature}{compat}{$compat} < 0;
                }
            }
        }
    }
}

sub _cleanup_bundled_features {
    my ( $self, $doc, $old_num ) = @_;
    my $version_num       = $self->version_num;
    my $feature_in_bundle = $self->{feature_in_bundle};
    my %enabled_in_code;

    # drop features enabled in this bundle
    # (also if they were enabled with `use experimental`)
    for my $module (qw( feature experimental )) {
        for my $use_line ( _find_include( $module => $doc, 'use' ) ) {
            my @old_args = _ppi_list_to_perl_list( $use_line->arguments );
            $enabled_in_code{$_}++ for @old_args;
            my @new_args =                # keep enabling features
              grep exists $feature{$_}    # that actually exist and are
              && !exists $feature_in_bundle->{enabled}{$_},    # not enabled yet
              @old_args;
            next if @new_args == @old_args;    # nothing to change
            if (@new_args) {    # replace old statement with a smaller one
                my $new_use_line = PPI::Document->new(
                    \"use $module @{[ join ', ', map qq{'$_'}, @new_args]};" );
                $use_line->insert_before( $_->remove )
                  for $new_use_line->elements;
                $use_line->remove;
            }
            else { _drop_statement($use_line); }
        }
    }

    # deal with compat modules
    $self->_handle_compat_modules($doc);

    # apply some feature shine when crossing the feature enablement boundary
    for my $feature ( sort grep exists $feature{$_}{enabled}, keys %feature_shine ) {
        my $feature_enabled = $feature{$feature}{enabled};
        $feature_shine{$feature}->($doc)
          if $old_num < $feature_enabled         # code from before the feature
          && $version_num >= $feature_enabled    # bumped to after the feature
          && !$enabled_in_code{$feature};        # and not enabling the feature
    }

    # drop disabled features that are not part of the bundle
    for my $no_feature ( _find_include( feature => $doc, 'no' ) ) {
        my @old_args = _ppi_list_to_perl_list( $no_feature->arguments );
        my @new_args =                # keep disabling features
          grep exists $feature{$_}    # that actually exist and are
          && !exists $feature_in_bundle->{disabled}{$_},    # not disabled yet
          @old_args;
        next if @new_args == @old_args;                     # nothing to change
        if (@new_args) {    # replace old statement with a smaller one
            my $new_no_feature = PPI::Document->new(
                \"no feature @{[ join ', ', map qq{'$_'}, @new_args]};" );
            $no_feature->insert_before( $_->remove )
              for $new_no_feature->elements;
            $no_feature->remove;
        }
        else { _drop_statement($no_feature); }
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
        if ( @new_args || @keep_args ) {    # replace old statement
            my $new_warn_line = PPI::Document->new(
                \"no warnings @{[ join ', ', map qq{'$_'}, @new_args, @keep_args]};"
            );
            $warn_line->insert_before( $_->remove )
              for $new_warn_line->elements;
            $warn_line->remove;
        }
        else { _drop_statement($warn_line); }
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
    my $code   = Path::Tiny->new($file)->slurp;
    my $bumped = $self->bump( $code, $file );
    if ( $bumped ne $code ) {
        $file->spew($bumped);
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
    Path::Tiny->new($file)->spew( $bumped_doc->serialize ) if $version;
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
    $perv->bump_file($filename);

    # safe versions (check the result compiles)

    my $bumped_ppi  = $perv->bump_ppi_safely($ppi_doc);
    my $bumped_code = $perv->bump_safely($code);
    $perv->bump_file_safely( $filename, $version_limit );

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
turn it into a string suitable for C<use VERSION>.

To protect against simple mistakes (e.g. passing C<5.36> instead of
C<v5.36>), the constructor does some sanity checking, and checks that
the given version:

=over 4

=item *

is greater than or equal to C<v5.10>,

=item *

is lower than the version of the Perl currently running,

=item *

is a stable Perl version.

=back

The constructor will also drops any sub-version information (so C<v5.36.2>
will be turned into C<v5.36>).

=head1 CLASS METHODS

=head2 feature_version

Return the version (in numeric format) of the feature set recognized
by this module. It is not possible to bump code over that version.

The current value of C<feature_version> is: C<5.040>.

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
The actual cause for the error is that Perl v5.36 doesn't support
multidimensional array emulation. This code will in fact fail to compile
with all versions greater or equal to C<v5.36>.

A I<safe way> to try to bump this code to C<v5.40> is to try with
C<v5.40>, detect it fails to compile, try again with C<v5.38> and
C<v5.36>, which also fail, until we hit C<v5.34> which compiles just
fine (because the C<multidimensional> feature is still enabled in that
bundle). Leaving us with the following code:

    use v5.34;
    my %h; $h{ 1, 2 } = 3;    # same as $foo{"1\x{1c}2"} = 3;

The code needs to be updated to not use multidimensional array emulation
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

=head1 EXPORTS

The following I<functions> can be optionally exported. Be aware that they
are mostly meant for internal use of the module and helper scripts.

=head2 version_fmt

    my $v = version_fmt( $version );

Return the given version (in string, v-string or float format) as a number.

This function will die if the given version is not a plausible Perl
version number, i.e. is strictly lower than C<5.010>.

Note that all the following functions start by normalizing their
argument by calling L</version_fmt>, meaning they will die in the same
circumstances.

=head2 version_use

    my $v = version_use( $version );

Return the given version (in string, v-string or float format) as
a string suitable for a C<use VERSION> line.

=head2 stable_version

    my $s = stable_version( $version );

Return the closest stable version lower or equal to the given version,
as a number.

=head2 stable_version_inc

    my $n = stable_version_inc( $version );

Return the stable version following the given version, as a number.

=head2 stable_version_dec

    my $p = stable_version_dec( $version );

Return the stable version preceding the given version, as a number.

=head1 ACKNOWLEDGMENT

This software was originally developed at Booking.com. With approval
from Booking.com, this software was released as open source, for which
the authors would like to express their gratitude.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2024 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# The following data is used to generate the %feature hash.
#
# It is generated using the bin/build_feature_data.pl script
# shipped with the distribution.
#
# The keys are:
# - known:    when perl first learnt about the feature
# - enabled:  when the feature was first enabled (may be before it was known)
# - disabled: when the feature was first disabled
# - compat:   replacement modules for features to be deprecated / added
#
# Different features have different lifecycles:
#
# * New features (i.e. additional behaviour that didn't exist in Perl v5.8):
#   - are 'known' in the Perl release that introduced them
#   - are 'enabled' either in the same version (e.g. 'say', 'state') or
#     after an "experimental" phase (e.g. 'signatures', 'bitwise')
#   - once enabled, they are not meant to be 'disabled'
#
# * Backwards compatibility features (features that existed in older
#   Perls,  but were later deemed undesirable, and scheduled for being
#   eventuall disabled or removed):
#   - are 'enabled' in the :default bundle (they were part of the old
#     Perl 5 behaviour) before they are even 'known' (a feature that
#     represents them was added to Perl).
#   - are meant to be manually disabled (with `no feature`), until a
#     later feature bundle eventually disables them by default.
#
# "compat" modules are meant to add support to the feature on perls where
# it's not available yet. They exist both for new features and backwards
# compatibility features. The number following the module name in the
# data structure below is the sum of 1 (if the module has an `import`
# method) and -1 (if the module has an `unimport` method).

__DATA__
            5.040 features known    enabled  disabled compat
                       say   5.010    5.010           Perl6::Say 1 Say::Compat 1
                     state   5.010    5.010
                    switch   5.010    5.010    5.036
           unicode_strings   5.012    5.012
                array_base   5.016    5.010    5.016
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
                  indirect   5.032    5.010    5.036  indirect 0
                       isa   5.032    5.036
      bareword_filehandles   5.034    5.010    5.038  bareword::filehandles 0
          multidimensional   5.034    5.010    5.036  multidimensional 0
                       try   5.034    5.040           Feature::Compat::Try 1 Syntax::Feature::Try 0 Syntax::Keyword::Try 0
                     defer   5.036                    Feature::Compat::Defer 1 Syntax::Keyword::Defer 0
   extra_paired_delimiters   5.036
                     class   5.038                    Feature::Compat::Class 1
               module_true   5.038    5.038
