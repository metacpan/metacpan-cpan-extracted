use Modern::Perl;
package Orbital::Transfer::System::Docker;
# ABSTRACT: Helper for Docker
$Orbital::Transfer::System::Docker::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;

classmethod is_inside_docker() {
	my $cgroup = path('/proc/1/cgroup');
	return -f $cgroup  && $cgroup->slurp_utf8 =~ m,/(lxc|docker)/[0-9a-f]{64},s;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::System::Docker - Helper for Docker

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
