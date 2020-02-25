package Module::Build::Parse::Yapp;

use strict;
use warnings;
use base 'Module::Build';

our $VERSION = '0.1.1'; # VERSION
# ABSTRACT: build Parse::Yapp parsers from source

use File::Find;
use File::Spec::Functions qw( catdir splitdir );
use Parse::Yapp;

sub new {
    my $self = shift;
    my %args = @_;
    $self->SUPER::new( %args );
}

sub process_yp_files {
    my $self = shift;

    find( { wanted => \&_find_parser, no_chdir => 1 }, 'lib' );
}

sub _find_parser {
    return unless /\.yp$/;

    my $pmfile = $_;
    $pmfile =~ s/\.yp$/.pm/;

    my @path = splitdir( $File::Find::name );
    my @pmpath = my @namespace = @path;

    unshift @pmpath, 'blib';
    $pmpath[-1] =~ s/\.yp$/.pm/;

    shift @namespace;
    $namespace[-1] =~ s/\.yp$//;

    _make_parser( $File::Find::name,
                  catdir( @pmpath ),
                  join '::', @namespace );
}

sub _make_parser {
    my( $inputfile, $outputfile, $classname ) = @_;

    my $parser = Parse::Yapp->new( inputfile => $inputfile );
    open( my $out, '>', $outputfile );
    print $out $parser->Output( classname => $classname );
    close $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Build::Parse::Yapp - build Parse::Yapp parsers from source

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    use Module::Build::Parse::Yapp;
    my $build = Module::Build::Parse::Yapp->new
        (
            module_name => 'Foo::Bar',
            ...other stuff here...
        );
    $build->add_build_element('yp');
    $build->create_build_script;

=head1 DESCRIPTION

Module::Build::Parse::Yapp is a subclass of L<Module::Build|Module::Build>
made to build L<Parse::Yapp|Parse::Yapp> parsers from the source. Thus,
prebuilt parsers do not have to be included in the source distribution.

Module::Build::Parse::Yapp looks for *.yp files under B<'lib'> and produces
Perl modules in place of them under B<'blib/lib'>. Therefore, a grammar file
B<'lib/A/B/C.yp'> will be converted to B<'blib/lib/A/B/C.pm'> with a package
name of B<'A::B::C'>.

=head1 SEE ALSO

perl(1), Module::Build(3), Parse::Yapp(3)

=head1 AUTHOR

Andrius Merkys <merkys@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andrius Merkys.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
