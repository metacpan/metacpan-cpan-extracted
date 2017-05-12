package Pod::Weaver::Section::BugsRT;
$Pod::Weaver::Section::BugsRT::VERSION = '0.52';

# ABSTRACT: Add a BUGS pod section for rt.cpan.org

use Moose;

with 'Pod::Weaver::Role::Section';

use Moose::Autobox;


sub weave_section {
    my ($self, $document, $input) = @_;

    my $zilla = $input->{zilla} or return;
    my $name = $zilla->name;

    my $bugtracker =
        sprintf 'http://rt.cpan.org/Public/Dist/Display.html?Name=%s', $name;

    # I prefer all lower case emails.
    my $email = "bug-".lc($name).'@rt.cpan.org';

    my $text =
        "Please report any bugs or feature requests to $email ".
        "or through the web interface at:\n".
        " $bugtracker";

    $document->children->push(
        Pod::Elemental::Element::Nested->new({
            command => 'head1',
            content => 'BUGS',
            children => [
                Pod::Elemental::Element::Pod5::Ordinary->new({content => $text}),
            ],
        }),
    );
}

no Moose;
1;



=pod

=head1 NAME

Pod::Weaver::Section::BugsRT - Add a BUGS pod section for rt.cpan.org

=head1 VERSION

version 0.52

=head1 SYNOPSIS

In C<weaver.ini>:

 [BugsRT]

=head1 OVERVIEW

This section plugin will produce a hunk of Pod that describes how to report bugs to rt.cpan.org.

=head1 METHODS

=head2 weave_section

adds the BUGS section.

=head1 AUTHOR

  Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SOURCE

You can contribute or fork this project via github:

http://github.com/mschout/pod-weaver-section-bugsrt

 git clone git://github.com/mschout/pod-weaver-section-bugsrt.git

=head1 BUGS

Please report any bugs or feature requests to bug-pod-weaver-section-bugsrt@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-BugsRT

=cut


__END__

