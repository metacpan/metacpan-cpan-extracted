package Pod::Index::Extract;

use 5.008;
$VERSION = '0.14';

use strict;
use warnings;

use base qw(Pod::Parser);

sub begin_input {
    my ($self) = @_;
    $self->cutting(0); # force parser to notice that it's in POD mode
}

sub verbatim {
    my ($self, $text, $line_num, $pod_para) = @_;

    # verbatim should't have the X<> attached
    return $self->ppi_done unless $self->{ppi_anchor_type};

    my $out_fh = $self->output_handle;
    print $out_fh $text;
    $self->{ppi_textblock_count}++;
}

sub textblock {
    my ($self, $text, $line_num, $pod_para) = @_;

    # should sanity check that the X<> is really here...
    #print "<<<$text>>>\n";

    my $out_fh = $self->output_handle;

    unless ($self->{ppi_anchor_type}) {
        $self->{ppi_anchor_type} = 'textblock';
        $self->ppi_start;
    }

    # only print the first paragraph if in textblock mode
    return $self->ppi_done if $self->{ppi_anchor_type} eq 'textblock' 
        and $self->{ppi_textblock_count};

    print $out_fh $text;
    $self->{ppi_textblock_count}++;
}

sub command {
    my ($self, $cmd, $text, $line_num, $pod_para)  = @_;

    # should sanity check that the X<> is really here...

    my $out_fh = $self->output_handle;

    unless ($self->{ppi_anchor_type}) {
        $self->{ppi_anchor_type} = 'command';
        $self->{ppi_command}     = $cmd; 
        $self->ppi_start;
        if ($cmd eq 'item') {
            print $out_fh "=over\n\n";
        }
    }

    return $self->ppi_done unless $self->{ppi_anchor_type} eq 'command';

    my $ppi_cmd = $self->{ppi_command}; 
    return $self->ppi_done unless $ppi_cmd =~ /^(?:head|item)/; # XXX
    
    # check if we are out of scope
    if ($self->{ppi_textblock_count}) {
        if ($ppi_cmd =~ /^head(\d)/) {
            my $initial_level = $1;
            if ($cmd =~ /^head(\d)/) {
                my $current_level = $1;
                return $self->ppi_done if $current_level <= $initial_level;
            }
        } elsif ($ppi_cmd =~ /^item/) {
            if ($cmd =~ /item|back/ and !$self->{ppi_depth}) {
                return $self->ppi_done;
            } elsif ($cmd eq 'over') {
                $self->{ppi_depth}++;
            } elsif ($cmd eq 'back') {
                $self->{ppi_depth}--;
            }
        } else {
            die "shouldn't be here ";
        }
    }

    print $out_fh $pod_para->raw_text;
}

sub ppi_start {
    my ($self) = @_;
}

sub ppi_done {
    my ($self) = @_;
    my $out_fh = $self->output_handle;
    if ($self->{ppi_command} and $self->{ppi_command} eq 'item') {
        print $out_fh "=back\n\n";
    }


    my $fh = $self->input_handle;
    seek $fh, 0, 2; # EOF
}

1;

__END__

=head1 NAME

Pod::Index::Extract - Extracts a "pod scope"

=head1 SYNOPSIS

    use Pod::Index::Extract;

    my $parser = Pod::Index::Extract->new;
    # [...] get $fh_in to the desired position
    $parser->parse_from_filehandle($fh_in, $fh_out);

=head1 DESCRIPTION

This module is a subclass of L<Pod::Parser>. It outputs POD without any
transformation; however, it only outputs the POD that is "in scope" as
defined in L<Pod::Index>.

To use this module, you first need to position a filehandle at the beginning of
the desired scope, and then call C<parse_from_filehandle> with that filehandle
for input. It will just print the POD until it reaches the end of the
scope, after which it will jump to the end of the file.

If the scope starts with an C<=item>, it will wrap it with an C<=over> and 
a C<=back>, so it can be used as valid POD in isolation.

=head1 VERSION

0.14

=head1 SEE ALSO

L<Pod::Index>,
L<Pod::Index::Entry>,
L<Pod::Parser>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut


