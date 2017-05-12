package Template::Patch;

use warnings;
use strict;

use Template::Extract;
use Template;

use base 'Class::Accessor::Ref';

our $VERSION = '0.03';

BEGIN {
    my @accs = (qw/ inp outp vars routput rinput _ext _tt conf/); 
    __PACKAGE__->mk_accessors(@accs);
    __PACKAGE__->mk_refaccessors(@accs);
 }

=head1 NAME

Template::Patch - Apply parameterized patches

=head1 SYNOPSIS

    $ metapatch --patch mychanges.mp < oldfile > newfile

    # or, programmatically:

    use Template::Patch;

    my $tp = Template::Patch->parse_patch_file($metapatch_file);
    $tp->extract($source);
    $tp->patch;
    $tp->print;

=head1 DESCRIPTION

Please see L<metapatch> for documentation. This module is experimental and
the API here is subject to change.

=head1 FUNCTIONS

This isn't very streamlined yet, and is subject to change.

=cut

sub new_from_file {
    my($class, $pfile) = @_;
    my($to, $from);

    die "$0: must supply --patch arg" unless defined $pfile;

    my $self = $class->new( { vars => {},
            conf => {}, routput => do{\my $output_port} } );

    open my $fh, "<", $pfile or die "$0: open: $pfile: $!";
    while (<$fh>) {
        if (!$from) {
            $from++, next if /^<{20}/;
            next if /^#/;
            $self->conf->{$1} = $2 if /([^:]+) \s* : \s* (.*?) \s* $/x;
        }

        $to++, next if /^>{20}/;

        ${ $self->get_ref($to ? 'outp' : 'inp' ) } .= $_;
    }
    die "$0: $pfile: no output template" unless $self->outp;


    # conf-related fixups
       # xxx: higher-order this, ew
    if (! $self->conf->{'anchor-start'}) {
        for my $tname (qw/ inp outp /) {
            my $tref = $self->get_ref($tname);
            $$tref = "[% pre %]" . $$tref;
        }
    }
    if (! $self->conf->{'anchor-end'}) {
        for my $tname (qw/ inp outp /) {
            my $tref = $self->get_ref($tname);
            chomp $$tref;
            $$tref .= "[% post %]";
        }
    }

    #::YY($self);
    return $self;
}

sub extract {
    my($self, $input) = @_;
    $self->_ext( Template::Extract->new );
    $self->_ext->extract(
            $self->inp,         # input template
            $input,             # actual data to parse
            $self->vars,        # dictionary for extracted data
        );
    # we need to keep a ref to input around for the case where no extraction
    # was successful.
    $self->rinput(\$input);
    #::YY($self->vars);
}

sub patch {
    my($self) = @_;

    # if the dictionary is empty, extract didn't find anything.
    # copy over the input, so we don't emit just a broken template.
    # XXX: copy or ref?
    if (0 == keys %{ $self->vars }) {
        $self->routput( $self->rinput );
        return;
    }

    $self->_tt( Template->new );
    $self->_tt->process( \$self->outp, $self->vars, $self->routput )
}

sub print { print ${ $_[0]->routput } }

#sub ::Y  { require YAML::Syck; YAML::Syck::Dump(@_) }
#sub ::YY { require Carp; Carp::confess(::Y(@_)) }

=head1 SEE ALSO

=over 4

=item L<metapatch>

=item L<Template::Toolkit>

=item L<Template::Extract>

=back

=head1 AUTHOR

Gaal Yahas, C<< <gaal at forum2.org> >>

=head1 CAVEATS

This module and the included C<metapatch> tool are in early stages of
gathering ideas and coming up with a good interface. They work (and have
saved me time), but expect change in the interfaces.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-patch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Patch>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Patch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Patch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Patch>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Patch>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Patch>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Audrey Tang for sausage machine (and general) havoc.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Gaal Yahas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Template::Patch
