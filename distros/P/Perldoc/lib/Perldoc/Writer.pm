package Perldoc::Writer;
use Perldoc::Base -Base;

field 'stringref';
field 'filehandle';
field 'filepath';
field 'handle' => -init => '$self->open_handle';

sub print {
    for my $target (qw(stringref filepath filehandle)) {
        if (defined $self->{$target}) {
            my $method = "_print_$target";
            return $self->$method(@_);
        }
    }
    die "No destination for Perldoc::Writer to write to";
}

sub _print_stringref {
    ${$self->stringref} .= shift(@_);
}

sub _print_filepath {
    my $filehandle = $self->handle;
    print $filehandle shift(@_);
}

sub _print_filehandle {
    my $filehandle = $self->filehandle;
    print $filehandle shift(@_);
}

sub open_handle {
    my $filepath = $self->filepath;
    $filepath = "> $filepath"
      unless $filepath =~ /^>/;
    open my $ouput, $filepath
      or die "Can't open '$filepath' for output:\n$!";
    return $filepath;
}

=head1 NAME

Perldoc::Writer - Writer Class for Perldoc Parsers

=head1 SYNOPSIS

    package Perldoc::Writer;

=head1 DESCRIPTION

Uniform writing interface.

XXX - Should be a mixin for Emitters.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

Audrey wrote the original code for this parser.

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
