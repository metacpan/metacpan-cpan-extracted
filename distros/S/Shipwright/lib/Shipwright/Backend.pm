package Shipwright::Backend;

use warnings;
use strict;
use UNIVERSAL::require;
use Shipwright::Util;

sub new {
    my $class = shift;
    my %args  = @_;

    confess_or_die 'need repository arg' unless exists $args{repository};

    $args{repository} =~ s/^\s+//;
    $args{repository} =~ s/\s+$//;

    # exception for svk repos, they can start with //
    if ( $args{repository} =~ m{^//} ) {
        $args{repository} = 'svk:'. $args{repository};
    }

    my $backend;
    if ( $args{repository} =~ /^([a-z]+)(?:\+([a-z]+))?:/ ) {
        ($backend) = $1;
    } else {
        confess_or_die "invalid repository, doesn't start with xxx: or xxx+yyy:";
    }

    my $module = find_module(__PACKAGE__, $backend);
    unless ( $module ) {
        confess_or_die "Couldn't find backend implementing '$backend'";
    }

    $module->require
        or confess_or_die "Couldn't load module '$module'"
            ." implementing backend '$backend': $@";
    return $module->new(%args);
}

1;

__END__

=head1 NAME

Shipwright::Backend - Backend

=head1 SYNOPSIS

    # shipwright some_command -r backend_type:path
    shipwright create -r svn:file:///svnrepo/shipwright/my_proj

=head1 DESCRIPTION

See <Shipwright::Manual::Glossary/shipyard> to understand its concept. Look
at list of </SUPPORTED BACKENDS> or L<IMPLEMENTING BACKENDS> if you want
add a new one.

=head1 SUPPORTED BACKENDS

Currently, the supported backends are L<FS|Shipwright::BACKEND::FS>, L<Git|Shipwright::BACKEND::Git>, L<SVK|Shipwright::BACKEND::SVK> and L<SVN|Shipwright::BACKEND::SVN>.

=head1 IMPLEMENTING BACKENDS

Each implementation of a backend is a subclass of L<Shipwright::Backend::Base>.

=head1 METHODS

This is a tiny class with only one method C<new> that loads
particular implementation class and returns instance of that
class.

=head2 new repository => "type:path"

Returns the backend object that corresponds to the type
defined in the repository argument.

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
