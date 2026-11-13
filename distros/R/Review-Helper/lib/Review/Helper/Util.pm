package Review::Helper::Util;
use v5.36;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw/json_encode json_decode gen_uuid now share_dir/;

use Cpanel::JSON::XS();
use Cwd();
use File::Basename qw/dirname/;
use File::Spec;
use UUID();

# Resolved at load time: __FILE__ may be relative to a directory we later leave.
my $CHECKOUT_SHARE = File::Spec->catdir(Cwd::abs_path(File::Spec->catdir(dirname(__FILE__), (File::Spec->updir) x 3)), 'share');

my $JSON = Cpanel::JSON::XS->new->canonical->utf8;

sub json_encode($data)  { $JSON->encode($data) }
sub json_decode($bytes) { $JSON->decode($bytes) }
sub gen_uuid()          { UUID::uuid7() }
sub now()               { time }

sub share_dir() {
    return $CHECKOUT_SHARE if -f File::Spec->catfile($CHECKOUT_SHARE, 'ux', 'html', 'index.html');

    require File::ShareDir;
    return File::ShareDir::dist_dir('Review-Helper');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Util - Small shared functions for Review::Helper.

=head1 DESCRIPTION

JSON, UUID and clock helpers used across the distribution. Nothing is
exported by default.

=head1 SYNOPSIS

    use Review::Helper::Util qw/json_encode json_decode gen_uuid now share_dir/;

    my $bytes = json_encode({b => 1, a => 2});    # '{"a":2,"b":1}'
    my $data  = json_decode($bytes);
    my $id    = gen_uuid();
    my $when  = now();

=head1 EXPORTS

=over 4

=item $bytes = json_encode($data)

Encode C<$data> as compact JSON with sorted keys, returned as UTF-8 bytes.

=item $data = json_decode($bytes)

Decode UTF-8 JSON bytes. Dies on invalid JSON.

=item $uuid = gen_uuid()

A new UUID v7 string.

=item $epoch = now()

The current time in integer Unix epoch seconds.

=item $dir = share_dir()

The distribution's share directory: F<ux> holds the page, F<skills> the
shipped skills and F<standards> the specifications and the schema. In a source
checkout it is F<share/> beside F<lib/>, whose entries are symlinks to the
repository's top-level F<ux>, F<skills> and F<standards> directories;
otherwise it is the installed distribution's share directory.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
