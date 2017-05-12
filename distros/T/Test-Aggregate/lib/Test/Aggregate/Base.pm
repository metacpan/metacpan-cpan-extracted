package Test::Aggregate::Base;

use strict;
use warnings;

use Carp 'croak';
use Test::Builder::Module;
use Test::More;
use File::Find;

use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA    = qw(Test::Builder::Module);

our $VERSION = '0.375';
$VERSION = eval $VERSION;

our $_pid = $$;

BEGIN { 
    $ENV{TEST_AGGREGATE} = 1;
    *CORE::GLOBAL::exit = sub {
        my ($package, $filename, $line) = caller;

      # Warn about exit being called unless there's been a fork()
      # (in which case some form of exit is expected).
      if( $_pid == $$ ){

        print STDERR <<"        END_EXIT_WARNING";
********
WARNING!
exit called under Test::Aggregate at:
File:    $filename
Package: $package
Line:    $line
WARNING!
********
        END_EXIT_WARNING

      }

        exit(@_);
    };
};

END {   # for VMS
    delete $ENV{TEST_AGGREGATE};
}

sub _code_attributes {
    qw/
        setup
        teardown
        startup
        shutdown
    /;
}

sub new {
    my ( $class, $arg_for ) = @_;

    unless ( exists $arg_for->{dirs} || exists $arg_for->{tests} ) {
        Test::More::BAIL_OUT("You must supply 'dirs' or 'tests'");
    }
    if ( exists $arg_for->{tests} && 'ARRAY' ne ref $arg_for->{tests} ) {
        Test::More::BAIL_OUT(
            "Argument for Test::Aggregate 'tests' key must be an array reference"
        );
    }
        
    $arg_for->{test_nowarnings} = 1 unless exists $arg_for->{test_nowarnings};
    $arg_for->{set_filenames}   = 1 unless exists $arg_for->{set_filenames};
    $arg_for->{findbin}         = 1 unless exists $arg_for->{findbin};
    my $dirs = delete $arg_for->{dirs};
    if ( defined $dirs ) {
        $dirs = [$dirs] if 'ARRAY' ne ref $dirs;
    }
    else {
        $dirs = [];
    }

    my $matching = qr//;
    if ( $arg_for->{matching} ) {
        $matching = delete $arg_for->{matching};
        unless ( 'Regexp' eq ref $matching ) {
            croak("Argument for 'matching' must be a pre-compiled regex");
        }
    }

    my $has_code_attributes;
    foreach my $attribute ( $class->_code_attributes ) {
        if ( my $ref = $arg_for->{$attribute} ) {
            if ( 'CODE' ne ref $ref ) {
                croak("Attribute ($attribute) must be a code reference");
            }
            else {
                $has_code_attributes++;
            }
        }
    }

    my $self = bless {
        dirs              => $dirs,
        matching          => $matching,
        _no_streamer      => 0,
        _packages         => [],
        aggregate_program => $0,
    } => $class;

    if ( delete $arg_for->{check_plan} ) {
        Carp::carp("'check_plan' is now deprecated and a no-op.");
    }
    $self->{$_} = delete $arg_for->{$_} foreach (
        qw/
        dry
        dump
        findbin
        no_generate_plan
        set_filenames
        shuffle
        test_nowarnings
        tests
        tidy
        verbose
        /,
        $class->_code_attributes
    );
    $self->{tests} ||= [];

    if ( my @keys = keys %$arg_for ) {
        local $" = ', ';
        croak("Unknown keys to &new:  (@keys)");
    }

    if ($has_code_attributes) {
        eval "use Data::Dump::Streamer";
        if ( my $error = $@ ) {
            $self->{_no_streamer} = 1;
            if ( my $dump = $self->_dump ) {
                warn <<"                END_WARNING";
Dump file ($dump) cannot be generated.  A code attributes was requested but
we cannot load Data::Dump::Streamer:  $error.
                END_WARNING
                $self->{dump} = '';
            }
        }
    }

    return $self;
}

# set from user data

sub _dump            { shift->{dump} || '' }
sub _dry             { shift->{dry} }
sub _should_shuffle  { shift->{shuffle} }
sub _matching        { shift->{matching} }
sub _set_filenames   { shift->{set_filenames} }
sub _findbin         { shift->{findbin} }
sub _dirs            { @{ shift->{dirs} } }
sub _startup         { shift->{startup} }
sub _shutdown        { shift->{shutdown} }
sub _setup           { shift->{setup} }
sub _teardown        { shift->{teardown} }
sub _tests           { @{ shift->{tests} } }
sub _tidy            { shift->{tidy} }
sub _test_nowarnings { shift->{test_nowarnings} }

sub _verbose        {
    my $self = shift;
    $self->{verbose} ? $self->{verbose} : 0;
}

# set from internal data
sub _no_streamer    { shift->{_no_streamer} }
sub _packages       { @{ shift->{_packages} } }

sub _get_tests {
    my $self = shift;
    my @tests;
    my $matching = $self->_matching;
    if ( $self->_dirs ) {
        find( {
                no_chdir => 1,
                wanted   => sub {
                    push @tests => $File::Find::name if /\.t\z/ && /$matching/;
                }
        }, $self->_dirs );
    }
    push @tests => $self->_tests;
    
    if ( $self->_should_shuffle ) {
        $self->_shuffle(@tests);
    }
    else {
        @tests = sort @tests;
    }
    return @tests;
}

sub _shuffle {
    my $self = shift;

    # Fisher-Yates shuffle
    my $i = @_;
    while ($i) {
        my $j = rand $i--;
        @_[ $i, $j ] = @_[ $j, $i ];
    }
    return;
}

sub _get_package {
    my ( $class, $file ) = @_;
    $file =~ s/\W//g;
    return $file;
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::Aggregate::Base - Base class for aggregated tests.

=head1 VERSION

Version 0.375

=head1 SYNOPSIS

    use base 'Test::Aggregate::base';

    sub run { ... }


=head1 DESCRIPTION

This module is for internal use only.

=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-aggregate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Aggregate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Aggregate::Base

You can also find information oneline:

L<http://metacpan.org/release/Test-Aggregate>

=head1 ACKNOWLEDGEMENTS

Many thanks to mauzo (L<http://use.perl.org/~mauzo/> for helping me find the
'skip_all' bug.

Thanks to Johan Lindström for pointing me to Apache::Registry.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
