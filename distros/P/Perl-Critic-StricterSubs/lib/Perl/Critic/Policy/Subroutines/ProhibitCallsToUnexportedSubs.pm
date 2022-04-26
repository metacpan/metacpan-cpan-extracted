package Perl::Critic::Policy::Subroutines::ProhibitCallsToUnexportedSubs;

use strict;
use warnings;
use base 'Perl::Critic::Policy';

use PPI::Document;
use File::PathList;

use Perl::Critic::Utils qw(
    :characters
    :severities
    &hashify
    &is_function_call
    &is_perl_builtin
    &is_qualified_name
    &policy_short_name
);

use Perl::Critic::StricterSubs::Utils qw{
    &find_exported_subroutine_names
    &find_subroutine_calls
};

#-----------------------------------------------------------------------------

our $VERSION = 0.06;

#-----------------------------------------------------------------------------

my $CONFIG_PATH_SPLIT_REGEX = qr/ \s* [|] \s* /xms;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return qw( at_inc_prefix use_standard_at_inc at_inc_suffix );
}

sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( strictersubs bugs ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %config ) = @_;
    my $self = bless {}, $class;

    my @at_inc_prefix;
    my @at_inc_suffix;

    if ( defined $config{at_inc_prefix} ) {
        @at_inc_prefix =
            split $CONFIG_PATH_SPLIT_REGEX, $config{at_inc_prefix};
    }
    if ( defined $config{at_inc_suffix} ) {
        @at_inc_prefix =
            split $CONFIG_PATH_SPLIT_REGEX, $config{at_inc_suffix};
    }

    my $use_standard_at_inc = $config{use_standard_at_inc};
    if (not defined $use_standard_at_inc) {
        $use_standard_at_inc = 1;
    }

    my @inc = @at_inc_prefix;
    if ($use_standard_at_inc) {
        push @inc, @INC;
    }
    push @inc, @at_inc_suffix;

    die policy_short_name(__PACKAGE__), " has no directories in its module search path.\n"
        if not @inc;


    $self->{_inc} = File::PathList->new( paths => \@inc, cache => 1 );
    $self->{_exports_by_package} = {};
    return $self;
}

#-----------------------------------------------------------------------------

sub _get_inc {
    my $self = shift;
    return $self->{_inc};
}

sub _get_exports_by_package {
    my $self = shift;
    return $self->{_exports_by_package}
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, undef, $doc) = @_;

    my @violations   = ();
    my $expl = q{Violates encapsulation};

    for my $sub_call ( find_subroutine_calls($doc) ) {
        next if not is_qualified_name( $sub_call );

        my ($package, $sub_name)  = $self->_parse_subroutine_call( $sub_call );
        next if _is_builtin_package( $package );

        my $exports = $self->_get_exports_for_package( $package );
        if ( not exists $exports->{ $sub_name } ){

            my $desc = qq{Subroutine "$sub_name" not exported by "$package"};
            push @violations, $self->violation( $desc, $expl, $sub_call );
        }

    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _parse_subroutine_call {
    my ($self, $sub_call) = @_;
    return if not $sub_call;

    my $sub_name     = $EMPTY;
    my $package_name = $EMPTY;

    if ($sub_call =~ m/ \A &? (.*) :: ([^:]+) \z /xms) {
        $package_name = $1;
        $sub_name = $2;
    }

    return ($package_name, $sub_name);
}


#-----------------------------------------------------------------------------

sub _get_exports_for_package {
    my ( $self, $package_name ) = @_;

    my $exports = $self->_get_exports_by_package()->{$package_name};
    if (not $exports) {
        $exports = {};

        my $file_name =
            $self->_get_file_name_for_package_name( $package_name );

        if ($file_name) {
            $exports =
                { hashify ( $self->_get_exports_from_file( $file_name ) ) };
        }

        $self->_get_exports_by_package()->{$package_name} = $exports;
    }

    return $exports;
}

#-----------------------------------------------------------------------------

sub _get_exports_from_file {
    my ($self, $file_name) = @_;

    my $doc = PPI::Document->new($file_name);
    if (not $doc) {
        my $pname = policy_short_name(__PACKAGE__);
        die "$pname: could not parse $file_name: $PPI::Document::errstr\n";
    }

    return find_exported_subroutine_names( $doc );
}

#-----------------------------------------------------------------------------

sub _get_file_name_for_package_name {
    my ($self, $package_name) = @_;

    my $partial_path = $package_name;
    $partial_path =~ s{::}{/}xmsg;
    $partial_path .= '.pm';

    my $full_path = $self->_find_file_in_at_INC( $partial_path );
    return $full_path;
}

#-----------------------------------------------------------------------------

sub _find_file_in_at_INC {  ## no critic (NamingConventions::Capitalization)
    my ($self, $partial_path) = @_;

    my $inc = $self->_get_inc();
    my $full_path = $inc->find_file( $partial_path );

    if (not $full_path) {
        #TODO reinstate Elliot's error message here.
        my $policy_name = policy_short_name( __PACKAGE__ );
        warn qq{$policy_name: Cannot find source file "$partial_path"\n};
        return;
    }

    return $full_path;
}

#-----------------------------------------------------------------------------

my %BUILTIN_PACKAGES = hashify( qw(CORE CORE::GLOBAL UNIVERSAL main), $EMPTY );

sub _is_builtin_package {
    my ($package_name) = @_;
    return exists $BUILTIN_PACKAGES{$package_name};
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords callee's

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitCallsToUnexportedSubs

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs|Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

Many Perl modules define their public interface by exporting subroutines via
L<Exporter|Exporter>.  The goal of this Policy is to enforce encapsulation by by
prohibiting calls to subroutines that are not listed in the callee's C<@EXPORT>
or C<@EXPORT_OK>.

=head1 LIMITATIONS

This Policy does not properly deal with the L<only|only> pragma or modules that
don't use L<Exporter|Exporter> for their export mechanism, such as L<CGI|CGI>.  In the
near future, we might fix this by allowing you configure the policy with
a list of packages that are exempt from this policy.

=head1 DIAGNOSTICS

=over

=item C<Subroutines::ProhibitCallsToUnexportedSubs: Cannot find source file>

This warning usually indicates that the file under analysis includes modules
that are not installed in this perl's <@INC> paths.  See L</"CONFIGURATION">
for controlling the C<@INC> list this Policy.

This warning can also happen when one of the included modules contains
multiple packages, or if the package name doesn't match the file name.
L<Perl::Critic|Perl::Critic> advises against both of these conditions, and has additional
Policies to help enforce that.

=back

=head1 SEE ALSO

L<Perl::Critic::Policy::Modules::ProhibitMultiplePackages|Perl::Critic::Policy::Modules::ProhibitMultiplePackages>

L<Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage|Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
