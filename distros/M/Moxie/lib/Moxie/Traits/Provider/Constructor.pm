package Moxie::Traits::Provider::Constructor;
# ABSTRACT: built in traits

use v5.22;
use warnings;
use experimental qw[
    signatures
    postderef
];

use Method::Traits ':for_providers';

use Carp      ();
use MOP::Util ();

our $VERSION   = '0.07';
our $AUTHORITY = 'cpan:STEVAN';

sub strict ( $meta, $method, %signature ) : OverwritesMethod {

    # XXX:
    # Consider perhaps supporting something
    # like the Perl 6 signature format here,
    # which would give us a more sophisticated
    # way to specify the constructor API
    #
    # The way MAIN is handled is good inspiration maybe ...
    # http://perl6maven.com/parsing-command-line-arguments-perl6
    #
    # - SL

    my $class_name  = $meta->name;
    my $method_name = $method->name;

    Carp::confess('The `strict` trait can only be applied to BUILDARGS')
        if $method_name ne 'BUILDARGS';

    if ( %signature ) {

        my @all       = sort keys %signature;
        my @required  = grep !/\?$/, @all;

        my $max_arity = 2 * scalar @all;
        my $min_arity = 2 * scalar @required;

        # use Data::Dumper;
        # warn Dumper {
        #     class     => $meta->name,
        #     all       => \@all,
        #     required  => \@required,
        #     min_arity => $min_arity,
        #     max_arity => $max_arity,
        # };

        $meta->add_method('BUILDARGS' => sub ($self, @args) {

            my $arity = scalar @args;

            Carp::confess('Constructor for ('.$class_name.') expected '
                . (($max_arity == $min_arity)
                    ? ($min_arity)
                    : ('between '.$min_arity.' and '.$max_arity))
                . ' arguments, got ('.$arity.')')
                if $arity < $min_arity || $arity > $max_arity;

            my $proto = $self->UNIVERSAL::Object::BUILDARGS( @args );

            my @missing;
            # make sure all the expected parameters exist ...
            foreach my $param ( @required ) {
                push @missing => $param unless exists $proto->{ $param };
            }

            Carp::confess('Constructor for ('.$class_name.') missing (`'.(join '`, `' => @missing).'`) parameters, got (`'.(join '`, `' => sort keys $proto->%*).'`), expected (`'.(join '`, `' => @all).'`)')
                if @missing;

            my (%final, %super);

            #warn "---------------------------------------";
            #warn join ', ' => @all;

            # do any kind of slot assignment shuffling needed ....
            foreach my $param ( @all ) {

                #warn "CHECKING param: $param";

                my $from = $param;
                $from =~ s/\?$//;
                my $to   = $signature{ $param };

                #warn "PARAM: $param FROM: ($from) TO: ($to)";

                if ( $to =~ /^super\((.*)\)$/ ) {
                    $super{ $1 } = delete $proto->{ $from }
                         if $proto->{ $from };
                }
                else {
                    if ( exists $proto->{ $from } ) {

                        #use Data::Dumper;
                        #warn "BEFORE:", Dumper $proto;

                        # now grab the slot by the correct name ...
                        $final{ $to } = delete $proto->{ $from };

                        #warn "AFTER:", Dumper $proto;
                    }
                    #else {
                        #use Data::Dumper;
                        #warn "NOT FOUND ($from) :", Dumper $proto;
                    #}
                }
            }

            # inherit keys ...
            if ( keys %super ) {
                my $super_proto = $self->next::method( %super );
                %final = ( $super_proto->%*, %final );
            }

            if ( keys $proto->%* ) {

                #use Data::Dumper;
                #warn Dumper +{
                #    proto => $proto,
                #    final => \%final,
                #    super => \%super,
                #    meta  => {
                #        class     => $meta->name,
                #        all       => \@all,
                #        required  => \@required,
                #        min_arity => $min_arity,
                #        max_arity => $max_arity,
                #    }
                #};

                Carp::confess('Constructor for ('.$class_name.') got unrecognized parameters (`'.(join '`, `' => keys $proto->%*).'`)');
            }

            return \%final;
        });
    }
    else {
        $meta->add_method('BUILDARGS' => sub ($self, @args) {
            Carp::confess('Constructor for ('.$class_name.') expected 0 arguments, got ('.(scalar @args).')')
                if @args;
            return $self->UNIVERSAL::Object::BUILDARGS();
        });
    }
}

1;

__END__

=pod

=head1 NAME

Moxie::Traits::Provider::Constructor - built in traits

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This is a L<Method::Traits> provider module which L<Moxie> enables by
default. These are documented in the L<METHOD TRAITS> section of the
L<Moxie> documentation.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
