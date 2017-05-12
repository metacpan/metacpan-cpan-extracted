package Perldoc::Reader;
use Perldoc::Base -Base;

field 'string';
field 'stringref';
field 'filehandle';
field 'filepath';

sub all {
    for my $source (qw(string stringref filepath filehandle)) {
        if (defined $self->{$source}) {
            my $method = "_all_$source";
            return $self->$method();
        }
    }
    die "No input to read";
}

sub _all_string {
    return $self->string;
}

sub _all_stringref {
    return ${$self->stringref};
}

sub _all_filepath {
    my $filepath = $self->filepath;
    open my $input, $filepath
      or die "Can't open '$filepath' for input:\n$!";
    local $/;
    return <$input>
}

sub _all_filehandle {
    my $filehandle = $self->filehandle;
    local $/;
    return <$filehandle>;
}

=head1 NAME

Perldoc::Reader - Reader Class for Perldoc Parsers

=head1 SYNOPSIS

    package Perldoc::Reader;

=head1 DESCRIPTION

Uniform reading interface.

XXX - Should be a mixin for Parsers.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

Audrey wrote the original code for this parser.

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
