package ShipIt::Step::Twitter;

use strict;
use warnings;
use Net::Twitter;
use YAML 'LoadFile';


our $VERSION = '0.05';


use base qw(ShipIt::Step);


sub init {
    my ($self, $conf) = @_;
    my $config_file = $conf->value('twitter.config');
    defined $config_file || die "twitter.config not defined in config\n";

    $config_file =~ s/~/$ENV{HOME}/;

    -e $config_file || die "twitter.config: $config_file does not exist\n";
    -r $config_file || die "twitter.config: $config_file is not readable\n";

    $self->{config} = LoadFile($config_file);

    defined $self->{config}{username} or
        die "$config_file: no username defined\n";
    defined $self->{config}{password} or
        die "$config_file: no password defined\n";

    $self->{message} =
        $conf->value('twitter.message') || 'shipped %d %v - soon at %u';

    $self->{distname} = $conf->value('twitter.distname');
    defined $self->{distname} || print
        "twitter.distname not defined; will try to read it from META.yml later.\n";
}


sub run {
    my ($self, $state) = @_;

    my $version = $state->version;
    my $metafile = 'META.yml';
    if (!(defined $self->{distname}) && -e $metafile) {
        print "twitter.distname not defined; reading $metafile...\n";
        my $meta = LoadFile($metafile);
        $self->{distname} = $meta->{name};
        $version ||= $meta->{version};
    }
    defined $self->{distname} || die
        "twitter.distname not defined in config, and can't read it from META.yml\n";

    my %vars = (
        d => $self->{distname},
        u => "http://search.cpan.org/dist/$self->{distname}",
        v => $version,
        '%' => '%'
    );

    (my $message = $self->{message}) =~ s/%(.)/ $vars{$1} || '%'.$1 /ge;

    # warn(), don't die(), if we couldn't send the message, because this
    # step will presumably come after uploading to CPAN, so we don't want
    # to skip the rest of the shipit process just because of that.

    if ($state->dry_run) {
        warn "*** DRY RUN, not twittering!\n";
        warn "message: $message\n";
        return;
    }

    my $twitter = Net::Twitter->new(
        username => $self->{config}{username},
        password => $self->{config}{password},
    );

    $twitter->update($message) or warn "couldn't send message to twitter\n";
}


1;


__END__

=head1 NAME

ShipIt::Step::Twitter - ShipIt step to announce the upload on Twitter

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This L<ShipIt> step announces the upload to Twitter.

To use it, just list it in your C<.shipit> file. You might want to use it
after the C<UploadCPAN> step, as it is not a good idea to announce the
upload before it has gone through - something might go wrong with the upload.

If this step fails - maybe Twitter is down - a warning is issued, but the
shipit process doesn't die. This is because you might have uploaded the
distribution to CPAN already, and it would be a shame for the whole process to
die just because you're not able to twitter.

=head1 CONFIGURATION

In the C<.shipit> file:

    twitter.config = /path/to/config/file
    twitter.distname = Foo-Bar
    twitter.message = shipped %d %v - soon at %u

You can define three configuration values for this step:

=over 4

=item twitter.config

This is the location of the file that contains the Twitter username and
password in YAML style. I keep mine in C<~/.twitterrc>. The first tilde is
expanded to the user's home directory. An example file could look like this:

    username: foobar
    password: flurble

The reason not to keep the username and password in the C<.shipit> file
directly has to with security. The C<.shipit> file will generally be in the
distribution's base directory, so it is easy to make a mistake and to include
it in the C<MANIFEST>. This would lead to the password being published on
CPAN.

This variable is mandatory.

=item twitter.distname

This variable is optional; it is the distribution's name. If the variable is
not defined, the step will try to read the distribution name from the META.yml
file.

=item twitter.message

This variable is optional; it is the message to send to Twitter. You can use
placeholders, which will be expanded. If the variable is not defined, this
default message will be used:

    shipped %d %v - soon at %u

The following placeholders are recognized:

=over 4

=item %d

Will be expanded to the distribution name that you defined in
C<twitter.distname>.

=item %u

Will be expanded to the distribution's CPAN URL - if the distribution name is
C<Foo-Bar>, for example, the URL will be
C<http://search.cpan.org/dist/Foo-Bar>.

=item %v

Will be expanded to the version of the distribution you're shipping.

=item %%

Will result in a percent sign.

=back

=back

=head1 FUNCTIONS

=over 4

=item init

Initializes the ShipIt step object from the shipit configuration file and then
the twitter configuration file.

=item run

Does the actual twittering.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

