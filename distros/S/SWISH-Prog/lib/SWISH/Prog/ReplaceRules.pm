package SWISH::Prog::ReplaceRules;
use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Scalar::Util qw( blessed );
use Carp;
use Data::Dump qw( dump );
use Text::ParseWords;

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(qw( rules ));

=pod

=head1 NAME

SWISH::Prog::ReplaceRules - filename mangler

=head1 SYNOPSIS

 use SWISH::Prog::ReplaceRules;
 my $rules = SWISH::Prog::ReplaceRules->new(
   qq(replace "the string you want replaced" "what to change it to"),
   qq(remove  "a string to remove"),
   qq(prepend "a string to add before the result"),
   qq(append  "a string to add after the result"),
   qq(regex   "/search string/replace string/options"),
 );
 my $uri = 'foo/bar/baz';
 my $modified_uri = $rules->apply($uri);

=head1 DESCRIPTION

SWISH::Prog::ReplaceRules is a pure Perl replacement for the ReplaceRules
configuration feature in Swish-e.

This class is typically used internally by SWISH::Prog. The filter()
feature of SWISH::Prog is generated to use ReplaceRules if they are defined
in a SWISH::Prog::Config object or config file.

=head1 METHODS

=head2 new( I<rules> )

Constructor for new ReplaceRules object. I<rules> should be an array
of strings as defined in
L<http://swish-e.org/docs/swish-config.html#replacerules>.
 
=head2 init

Internal method called by new(). Expects an array of rule strings.

=head2 rules

Get/set the array ref of parsed rules.

=cut

# override new() to allow for single argument string instead of hashref.
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
    return $self;
}

sub init {
    my $self = shift;
    $self->SUPER::init( rules => $self->_parse_rules(@_) );
    return $self;
}

sub _parse_rules {
    my $self = shift;
    my @rules;
    for my $r (@_) {
        my $rule = {};
        my ( $action, $target )
            = (
            $r =~ m/^\ *(replace|remove|prepend|append|regex)\s+(.+)$/is );
        $action = lc($action);
        if ( $action eq 'regex' ) {
            ($target) = shellwords($target);
            my ( $delim, $before, $after, $opts )
                = ( $target =~ m!^(.)(.+?)\1(.+?)\1(.+)$! );

            $rule->{target} = {
                delim  => $delim,
                before => $before,
                after  => $after,
                opts   => $opts,
            };

        }
        elsif ( $action eq 'replace' ) {
            my ( $before, $after ) = shellwords($target);

            #warn "before:$before after:$after";
            $rule->{target} = {
                before => $before,
                after  => $after,
            };

        }
        else {
            ( $rule->{target} ) = shellwords($target);
        }

        $rule->{action} = $action;
        $rule->{orig}   = $r;
        push @rules, $rule;
    }

    #warn "rules: " . dump \@rules;

    return \@rules;
}

=head2 apply( I<string> )

Apply the rules in the object against I<string>. Returns a modified
copy of I<string>.

=cut

sub apply {
    my $self = shift;
    my $str  = shift;
    if ( !defined $str ) {
        croak "string required";
    }

    #dump $self;

    for my $rule ( @{ $self->{rules} } ) {
        my $action = $rule->{action};
        my $target = $rule->{target};
        my $orig   = $rule->{orig};

        #warn "apply '$orig' to '$str'\n";

        if ( $action eq 'prepend' ) {
            $str = $target . $str;
        }
        if ( $action eq 'append' ) {
            $str .= $target;
        }
        if ( $action eq 'remove' ) {
            $str =~ s/$target//g;
        }
        if ( $action eq 'replace' ) {
            my $b = $target->{before};
            my $a = $target->{after};
            $str =~ s/$b/$a/g;
            die "Bad rule: $orig ($@)" if $@;
        }
        if ( $action eq 'regex' ) {
            my $d    = $target->{delim};
            my $b    = quotemeta( $target->{before} );
            my $a    = quotemeta( $target->{after} );
            my $o    = $target->{opts};
            my $code = "\$str =~ s/$b/$a/$o";

            #warn "code='$code'\n";
            eval "$code";
            die "Bad rule: $orig ($@)" if $@;
        }

        #warn "$orig applied to '$str'\n";
    }
    return $str;
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>, L<http://swish-e.org/docs/swish-config.html#replacerules>
