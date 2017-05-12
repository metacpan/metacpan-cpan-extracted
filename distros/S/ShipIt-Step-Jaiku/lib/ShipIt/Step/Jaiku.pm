package ShipIt::Step::Jaiku;

use strict;
use warnings;
use Net::Jaiku;
use YAML 'LoadFile';


our $VERSION = '0.01';


use base qw(ShipIt::Step);


sub init {
    my ($self, $conf) = @_;
    my $config_file = $conf->value('jaiku.config');
    defined $config_file || die "jaiku.config not defined in config\n";

    $config_file =~ s/~/$ENV{HOME}/;

    -e $config_file || die "jaiku.config: $config_file does not exist\n";
    -r $config_file || die "jaiku.config: $config_file is not readable\n";

    $self->{config} = LoadFile($config_file);

    defined $self->{config}{username} or
        die "$config_file: no username defined\n";
    defined $self->{config}{userkey} or
        die "$config_file: no userkey defined\n";

    for my $key (qw(distname message)) {
        my $value = $conf->value("jaiku.$key");
        defined $value || die "jaiku.$key not defined in config\n";
        $self->{$key} = $value;
    }
}


sub run {
    my ($self, $state) = @_;

    my %vars = (
        d => $self->{distname},
        u => "http://search.cpan.org/dist/$self->{distname}",
        v => $state->version,
        '%' => '%'
    );

    (my $message = $self->{message}) =~ s/%(.)/ $vars{$1} || '%'.$1 /ge;

    # warn(), don't die(), if we couldn't send the message, because this
    # step will presumably come after uploading to CPAN, so we don't want
    # to skip the rest of the shipit process just because of that.

    if ($state->dry_run) {
        warn "*** DRY RUN, not jaikuing!\n";
        warn "message: $message\n";
        return;
    }

    my $jaiku = Net::Jaiku->new(
        username => $self->{config}{username},
        userkey  => $self->{config}{userkey},
    );

    $jaiku->setPresence(message => $message) or
        warn "couldn't send message to jaiku\n";
}


1;


__END__



=head1 NAME

ShipIt::Step::Jaiku - ShipIt step to announce the upload on Jaiku

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This L<ShipIt> step announces the upload to Jaiku.

To use it, just list it in your C<.shipit> file. You might want to use it
after the C<UploadCPAN> step, as it is not a good idea to announce the
upload before it has gone through - something might go wrong with the upload.

If this step fails - maybe Jaiku is down - a warning is issued, but the
shipit process doesn't die. This is because you might have uploaded the
distribution to CPAN already, and it would be a shame for the whole process to
die just because you're not able to jaiku.

=head1 CONFIGURATION

In the C<.shipit> file:

    jaiku.config = /path/to/config/file
    jaiku.distname = Foo-Bar
    jaiku.message = shipped %d %v - soon at %u

You have to define three configuration values for this step:

=over 4

=item jaiku.config

This is the location of the file that contains the Jaiku username and
userkey in YAML style. I keep mine in C<~/.jaikurc>. The first tilde is
expanded to the user's home directory. An example file could look like this:

    username: foobar
    userkey: flurble

You can retrieve your userkey from L<http://api.jaiku.com/>.

The reason not to keep the username and userkey in the C<.shipit> file
directly has to with security. The C<.shipit> file will generally be in the
distribution's base directory, so it is easy to make a mistake and to include
it in the C<MANIFEST>. This would lead to the userkey being published on
CPAN.

=item jaiku.distname

This is the distribution's name.

=item jaiku.message

This is the message to send to Jaiku. You can use placholders, which will be
expanded. The following placeholders are recognized:

=over 4

=item %d

Will be expanded to the distribution name that you defined in
C<jaiku.distname>.

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

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<shipitstepjaiku> tag.

=head1 VERSION 
                   
This document describes version 0.01 of L<ShipIt::Step::Jaiku>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<<bug-shipit-step-jaiku@rt.cpan.org>>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

