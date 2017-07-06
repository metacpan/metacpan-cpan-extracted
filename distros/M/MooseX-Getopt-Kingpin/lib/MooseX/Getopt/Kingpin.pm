package MooseX::Getopt::Kingpin;
use Moose::Role;

use Safe::Isa;

our $VERSION = '0.1.2';

=head1 NAME

MooseX::Getopt::Kingpin - A Moose role for processing command lines options via Getopt::Kingpin

=head1 SYNOPSIS

    ### In your class
    package MyClass {
        use Moose;
        with 'MooseX::Getopt::Kingpin';

        my $lines_default = 10;
        has 'lines' => (
            is            => 'ro',
            isa           => 'Int',
            default       => $lines_default,
            documentation => sub ($kingpin) {
                $kingpin->flag('lines', 'print first N lines')
                  ->default($lines_default)
                  ->short('n')
                  ->int();
            },
        );

        has 'input_file' => (
            is            => 'ro',
            isa           => 'Path::Tiny',
            required      => 1,
            documentation => sub ($kingpin) {
                $kingpin->arg('input_file', 'input_file')
                  ->required
                  ->existing_file();
            },
        );

        has 'other_attr' => (is => 'ro', isa => 'Str');
    };

    my $kingpin = Getopt::Kingpin->new();
    my $other_flag = $kingpin->flag('other_flag', 'this flag do something ...')->bool();
    $kingpin->version($MyClass::VERSION);
    MyClass->new_with_options(
        $kingpin,
        other_attr => 'xxx'
    );

    if $other_flag {
        ...
    }

=head1 DESCRIPTION

This is a role which provides an alternate constructor for creating objects using parameters passed in from the command line.

Thi role use L<Getopt::Kingpin> as command line processor, MOP and documentation trick.

=head1 METHODS

=head2 new_with_options($kingpin, %options)

C<$kingpin> instance of L<Getopt::Kingpin> is required

C<%options> - classic Moose options, override options set via kingpin

=cut

sub new_with_options {
    my ($class, $kingpin, %options) = @_;

    die 'First parameter ins\'t Getopt::Kingpin instance' if !$kingpin->$_isa('Getopt::Kingpin');

    my %kingpin_opts = generate_kingpin_options_from_moose_documentation($class, $kingpin),
    $kingpin->parse();

    return $class->new(
        map {$_ => $kingpin_opts{$_}->value()} keys %kingpin_opts,
        %options
    );
}

sub generate_kingpin_options_from_moose_documentation {
    my ($class, $kingpin) = @_;

    my %options;
    foreach my $attr (sort { $a->name cmp $b->name } $class->meta->get_all_attributes()) {
        if (ref $attr->documentation eq 'CODE') {
            $options{ $attr->name } = $attr->documentation->($kingpin);
        }
    }

    return %options;
}

=head1 SEE ALSO

=over

=item *

L<MooseX::Getopt>

=back

=head1 contributing

for dependency use [cpanfile](cpanfile)...

for resolve dependency use [carton](https://metacpan.org/pod/Carton) (or carton - is more experimental)

    carton install

for run test use C<minil test>

    carton exec minil test


if you don't have perl environment, is best way use docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton install
    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton exec minil test

=head2 warning

docker run default as root, all files which will be make in docker will be have root rights

one solution is change rights in docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended bash -c "carton install; chmod -R 0777 ."

or after docker command (but you must have root rights)

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR
Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
