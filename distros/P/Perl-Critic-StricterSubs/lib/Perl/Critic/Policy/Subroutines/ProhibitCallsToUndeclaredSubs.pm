package Perl::Critic::Policy::Subroutines::ProhibitCallsToUndeclaredSubs;

use strict;
use warnings;
use base 'Perl::Critic::Policy';

use Perl::Critic::StricterSubs::Utils qw(
    &find_declared_constant_names
    &find_declared_subroutine_names
    &find_imported_subroutine_names
    &find_subroutine_calls
    &get_package_names_from_include_statements
);

use Perl::Critic::Utils qw(
    :severities
    &hashify
    &is_qualified_name
    &words_from_string
);

#-----------------------------------------------------------------------------

our $VERSION = '0.07';

#-----------------------------------------------------------------------------

sub supported_parameters { return qw(exempt_subs)         }
sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( strictersubs bugs ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_exempt_subs} = {};

    if (defined $args{exempt_subs} ) {
        for my $qualified_sub ( words_from_string( $args{exempt_subs} ) ){
            my ($package, $sub_name) = _parse_sub_name( $qualified_sub );
            $self->{_exempt_subs}->{$package}->{$sub_name} = 1;
        }
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub _parse_sub_name {

    my $full_name = shift;

    if ( $full_name =~ m/\A ( .+ ) :: ([^:]+) \z/xms ) {

        my ($package_name, $sub_name) = ($1, $2);
        return ($package_name, $sub_name);
    }
    else {

        die qq{Sub name "$full_name" must be fully qualifed.\n};
    }
}

#-----------------------------------------------------------------------------

sub _is_exempt_subroutine {

    my ($self, $sub_name, $included_packages) = @_;
    for my $package ( @{$included_packages} ) {
        return 1 if exists $self->{_exempt_subs}->{$package}->{$sub_name};
    }

    return;
}

#-----------------------------------------------------------------------------

sub violates {

    my ($self, undef, $doc) = @_;

    my @declared_constants  = find_declared_constant_names( $doc );
    my @declared_sub_names  = find_declared_subroutine_names( $doc );
    my @imported_sub_names  = find_imported_subroutine_names( $doc );

    my %defined_sub_names = hashify(@declared_sub_names,
                                    @imported_sub_names,
                                    @declared_constants);

    my @included_packages = get_package_names_from_include_statements( $doc );

    my @violations;
    for my $elem ( find_subroutine_calls($doc) ){

        next if is_qualified_name( $elem );
        next if $self->_is_exempt_subroutine( $elem, \@included_packages );

        my ( $name ) = ( $elem =~ m{&?(\w+)}mxs );
        if ( not exists $defined_sub_names{$name} ){
            my $expl = q{This might be a major bug};
            my $desc = qq{Subroutine "$elem" is neither declared nor explicitly imported};
            push @violations, $self->violation($desc, $expl, $elem);
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitCallsToUndeclaredSubs

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs|Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

This Policy checks that every unqualified subroutine call has a matching
subroutine declaration in the current file, or that it explicitly appears in
the import list for one of the included modules.

Some modules do not use the L<Exporter|Exporter> interface, and rely on other
mechanisms to export symbols into your code.  In those cases, this Policy will
report a false violation.  However, you can instruct this policy to ignore a
particular subroutine name, as long as the appropriate package has been
included in your file.  See L</"CONFIGURATION"> for more details.

=head1 CONFIGURATION

A list of exempt subroutines for this Policy can defined by specifying
'exempt_subs' as a string of space-delimited, fully-qualified subroutine
names.  For example, putting this in your F<.perlcriticrc> file would allow
you to call the C<ok> and C<is> functions without explicitly importing or
declaring those functions, as long as the C<Test::More> package has been
included in the file somewhere.

    [Subroutines::ProhibitCallsToUndeclaredSubs]
    exempt_subs = Test::More::ok Test::More::is

By default, there are no exempt subroutines, but we're working on compiling a
list of the most common ones.

=head1 LIMITATIONS

This Policy assumes that the file has no more than one C<package> declaration
and that all subs declared within the file are, in fact, declared into that
same package.  In most cases, violating either of these assumptions means
you're probably doing something that you shouldn't do.  Think twice about what
you're doing.

Also, if you C<require> a module and subsequently call the C<import> method on
that module, this Policy will not detect the symbols that might have been
imported.  In which case, you'll probably get bogus violations.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright 2007-2024 Jeffrey Ryan Thalhammer and Andy Lester

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
