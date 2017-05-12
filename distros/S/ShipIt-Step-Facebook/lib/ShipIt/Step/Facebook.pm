package ShipIt::Step::Facebook;
use strict;
use warnings;
our $VERSION = '0.01';

use LWP::UserAgent;
use HTTP::Request::Common;
use YAML 'LoadFile';

use base qw(ShipIt::Step);

sub init {
    my ($self, $conf) = @_;

    my $config_file = $conf->value('facebook.config') || '~/.shipit.facebook';
    $config_file =~ s/~/$ENV{HOME}/;

    -e $config_file || die "facebook.config: $config_file does not exist\n";
    -r $config_file || die "facebook.config: $config_file is not readable\n";

    $self->{config} = LoadFile($config_file);

    defined $self->{config}{access_token} or
        die "$config_file: no access_token defined\n";

    $self->{message} =
        $conf->value('facebook.message') || 'shipped %d %v - soon at %f';

    $self->{target} =
        $conf->value('facebook.target') || $self->{config}{target} || 'me';

    $self->{distname} = $conf->value('facebook.distname');
    defined $self->{distname} || print
        "facebook.distname not defined; will try to read it from META.yml later.\n";
}

sub run {
    my ($self, $state) = @_;

    my $version = $state->version;
    my $metafile = 'META.yml';
    if (!(defined $self->{distname}) && -e $metafile) {
        print "facebook.distname not defined; reading $metafile...\n";
        my $meta = LoadFile($metafile);
        $self->{distname} = $meta->{name};
        $version ||= $meta->{version};
    }
    defined $self->{distname} || die
        "facebook.distname not defined in config, and can't read it from META.yml\n";

    my %vars = (
        d => $self->{distname},
        u => "http://search.cpan.org/dist/$self->{distname}",
        f => "http://frepan.org/dist/$self->{distname}",
        v => $version,
        '%' => '%'
    );

    (my $message = $self->{message}) =~ s/%(.)/ $vars{$1} || '%'.$1 /ge;

    # warn(), don't die(), if we couldn't send the message, because this
    # step will presumably come after uploading to CPAN, so we don't want
    # to skip the rest of the shipit process just because of that.

    if ($state->dry_run) {
        warn "*** DRY RUN, not facebooking!\n";
        warn "message: $message\n";
        return;
    }

    my $ua = LWP::UserAgent->new;
    my $target = $self->{target};
    my $res = $ua->request(
        POST "https://graph.facebook.com/$target/feed", [
            access_token => $self->{config}{access_token},
            message      => $message,
        ]
    );
    warn "couldn't send message to facebook\n" if $res->is_error;
}

1;
__END__

=head1 NAME

ShipIt::Step::Facebook - ShipIt step to announce the upload on Facebook

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This L<ShipIt> step announces the upload to Facebook.

To use it, just list it in your C<.shipit> file. You might want to use it
after the C<UploadCPAN> step, as it is not a good idea to announce the
upload before it has gone through - something might go wrong with the upload.

If this step fails - maybe Facebook is down - a warning is issued, but the
shipit process doesn't die. This is because you might have uploaded the
distribution to CPAN already, and it would be a shame for the whole process to
die just because you're not able to facebook.

=head1 GET FACEBOOK ACCESS_TOKEN AND STORE

run C<tools/init.pl> in this distribution.

Please follow the message of a script.

=head1 CONFIGURATION

In the C<.shipit> file:

    facebook.config = ~/.shipit.facebook
    facebook.distname = Foo-Bar
    facebook.message = shipped %d %v - soon at %f
    facebook.target = me

You can define three configuration values for this step:

The Variables is not mandatory.

=over 4

=item facebook.config

This is the location of the file that contains the Facebook access_token and
Wall target_id in YAML style. The first tilde is expanded to the user's home
directory. An example file could look like this:

    access_token: ACCESS_TOKEN
    target: me

The access_token is mandatory.


default '~/.shipit.facebook'

=item facebook.distname

This variable is optional; it is the distribution's name. If the variable is
not defined, the step will try to read the distribution name from the META.yml
file.

=item facebook.message

This variable is optional; it is the message to send to Facebook. You can use
placeholders, which will be expanded. If the variable is not defined, this
default message will be used:

    shipped %d %v - soon at %f

The following placeholders are recognized:

=over 4

=item %d

Will be expanded to the distribution name that you defined in
C<facebook.distname>.

=item %u

Will be expanded to the distribution's CPAN URL - if the distribution name is
C<Foo-Bar>, for example, the URL will be
C<http://search.cpan.org/dist/Foo-Bar>.

=item %f

Will be expanded to the distribution's FrePAN URL - if the distribution name is
C<Foo-Bar>, for example, the URL will be
C<http://frepan.org/dist/Foo-Bar>.

=item %v

Will be expanded to the version of the distribution you're shipping.

=item %%

Will result in a percent sign.

=back

=item facebook.target

you can select Wall page in message write.

When you want to carry out POST to Wall of C<http://www.facebook.com/kazuhiro.osawa>:

    facebook.target = kazuhiro.osawa

When you want to carry out POST to Wall of C<http://www.facebook.com/pages/Yappo/200453809970361>:

    facebook.target = 200453809970361

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<ShipIt>,
many code takes from L<ShipIt::Step::Twitter>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
