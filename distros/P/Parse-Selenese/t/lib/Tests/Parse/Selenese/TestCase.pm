package Tests::Parse::Selenese::TestCase;
use Test::Class::Most parent => 'Tests::Parse::Selenese::Base';
use Parse::Selenese;
use Parse::Selenese::TestCase;
use Path::Class;
use FindBin;
use File::Find qw(find);
use Try::Tiny;
use File::Temp ();
use Data::Dumper;

sub setup : Tests(setup) {
    my $self = shift;
    $self->SUPER::setup;
    $self->empty_test_case( Parse::Selenese::TestCase->new() );
}

sub startup : Tests(startup) {
    my $self = shift;
    $self->selenese_data_files(
        sub {
            my @selenese_data_files;
            my $case_data_dir = "$FindBin::Bin/data";
            find sub {
                push @selenese_data_files, $File::Find::name
                  if /_TestCase\.html$/;
            }, $case_data_dir;
            $self->{_selenese_data_files} = \@selenese_data_files;
          }
          ->()
    );
}

sub constructor : Tests {
    my $self = shift;
    my $case = new_ok("Parse::Selenese::TestCase");

    ok !$case->filename, 'TestCase without filename has undefined filename';
    ok !@{ $case->commands }, 'TestCase without commans commands 0 commands';
    ok !$case->base_url, 'Unparsed TestCase has no base_url';
    ok !$case->content,  'Unparsed TestCase has no content';

}

sub tests_that_should_die : Tests {
    my $self = shift;
    my $case = $self->empty_test_case();

    dies_ok { Parse::Selenese::parse(); }
    "dies trying to parse when given nothing to parse";

    dies_ok { Parse::Selenese::TestCase->new( filename => 'some_file' ); }
    'dies parsing a non existent file';

    dies_ok {
        my $c = Parse::Selenese::TestCase->new();
        $c->parse();
    }
    'dies trying to parse when given nothing to parse';

    my $not_existing_file = "t/this_file_does_not_exist";
    dies_ok {
        $case->filename($not_existing_file);
        $case->parse;
    }
    "dies trying to parse file that does not exist - $not_existing_file";
}

sub tests_that_should_live : Tests {
    my $self = shift;
    my $case = $self->empty_test_case();

    lives_ok {
        my $c =
          Parse::Selenese::TestCase->new(
            filename => $self->selenese_data_files->[0] );
    }
    $self->selenese_data_files->[0] . " - Lives new with filename arg";

    lives_ok {
        $case->filename( $self->selenese_data_files->[0] );
        $case->parse;
    }
    $self->selenese_data_files->[0] . " - Lives parsing a file";
}

sub test_each_stored_selenese_file : Tests {
    my $self = shift;
    my $case = $self->empty_test_case();

    foreach my $test_selenese_file ( @{ $self->selenese_data_files } ) {
        $test_selenese_file = File::Spec->abs2rel($test_selenese_file);
        my ( $file, $dir, $ext ) = File::Basename::fileparse( $test_selenese_file, qr/\.[^.]*/ );
        my $yaml_data_file = "$dir$file.yaml";

        # Parse the html file
        $case = Parse::Selenese::parse($test_selenese_file);

        # Test against the original parsed file
        _test_selenese( $case, $test_selenese_file );

        # Test against the saved yaml
        _test_yaml( $case, $yaml_data_file );

        # Test against the saved perl
        my $perl_data_file = "$dir$file.pl";

        _test_perl( $case, $perl_data_file );

    }
}

sub test_save_file : Tests {
    my $self = shift;

    my ($f) = grep { /hello_world_TestCase/ } @{ $self->selenese_data_files };
    my $c = Parse::Selenese::TestCase->new( filename => $f );

    my $fh    = File::Temp->new();
    my $fname = $fh->filename;
    lives_ok {
        $c->save($fname);
    }
    "could save file";
    ok( -e $fname, "save file exists" );

    my $new_case = Parse::Selenese::TestCase->new( filename => $fname );
    is( $new_case->filename, $fname, "Parsed saved case has correct filename" );

    # Change the filename of the new case to match that of our control
    $new_case->filename( $c->filename );

    is_deeply( $new_case->as_html, $c->as_html, "Parsing saved case gives an equilivent to the original case Selenese" );
    is_deeply( $new_case->as_perl, $c->as_perl, "Parsing saved case gives an equilivent to the original case Perl" );
    lives_ok {
        $new_case->save($fname);
    }
    "could save new file";

    #$self->selenese_data_files->[0] . " - Lives new with filename arg";
}

sub test_new_from_content : Tests {
    my $case = shift;
    return;

    #open my $io, '<:encoding(utf8)', $test_selenese_file;
    #my $content = join( '', <$io> );
    #close $io;
    #my $case2 = Parse::Selenese::TestCase->new( content => $content );
}

sub _test_selenese {
    my $case               = shift;
    my $test_selenese_file = shift;

    # do not test the known malformed cases.
    return if $test_selenese_file =~ /mal_/;

    open my $io, '<:encoding(utf8)', $test_selenese_file;
    my $content = join( '', <$io> );
    close $io;
    my $case2 = Parse::Selenese::TestCase->new( content => $content );
    my $case3 = Parse::Selenese::TestCase->new( filename => $test_selenese_file );
    $case3->parse;

    eq_or_diff $case->as_html, $content, $case->filename . ' - selenese output precisely';
    eq_or_diff $case2->as_html, $case->as_html, $case->filename . ' - as_html reparsed still is the same';
}

sub _num_tests_for_case {
    my $case       = shift;
    my $test_count = 0;
    for my $idx ( 0 .. @{ $case->commands } - 1 ) {
        my $command        = $case->commands->[$idx];
        my $command_values = $command->{values};
        $test_count++ for 0 .. @$command_values - 1;
    }
    return $test_count;
}

sub _test_perl {
    my $case           = shift;
    my $perl_data_file = shift;

    my $test_count = _num_tests_for_case($case);

  SKIP: {
        my $expected;
        try {
            open my $io, '<', $perl_data_file
              or die "Can't open perl data file";
            $expected = join( '', <$io> );
            close $io;
        }
        catch {
            #skip "$perl_data_file not found", $test_count;
            chomp $_;
            skip $_, $test_count;
        };
        unified_diff;
        eq_or_diff $case->as_perl, $expected, $case->filename . ' - perl output precisely';
    }
}

sub _test_yaml {
    my $case           = shift;
    my $yaml_data_file = shift;
    my $test_count     = _num_tests_for_case($case);

  SKIP: {
        my $yaml_data;
        try {
            use YAML qw'freeze thaw LoadFile';
            $yaml_data = LoadFile($yaml_data_file);
        }
        catch {
            my @reason = split /\n/;
            $reason[0] =~ s/\\n/ /g;
            skip $reason[0], $test_count;
        };

        # Load the yaml dump that matches
        is $case->short_name => $yaml_data->{short_name},
          $case->filename . " test case short name";
        my $want_file_name =
          Path::Class::File->new( @{ $yaml_data->{file_path_parts} } )->stringify;
        is $case->filename => $want_file_name,
          $case->filename . " filename";
        is $case->base_url => $yaml_data->{base_url},
          $case->filename . " base_url";

        is scalar @{ $case->commands } => scalar @{ $yaml_data->{commands} },
          $case->filename . " number of commands in";

        for my $idx ( 0 .. @{ $case->commands } - 1 ) {
            my $command             = $case->commands->[$idx];
            my $command_values      = $command->{values};
            my $yaml_command_values = $yaml_data->{commands}->[$idx]->{values};

            is $command_values->[$_] => $yaml_command_values->[$_],
              $case->filename
              . " command num $idx value $_ - $command_values->[$_]"
              for 0 .. @$command_values - 1;
        }
    }
}

1;
__END__

=head1 NAME

Parse::Selenese::TestCase::Test

=head1 SYNOPSIS

  use Parse::Selenese::TestCase;

=head1 DESCRIPTION

Parse::Selenese::TestCase::Test is a test class for Parse::Selenese::TestCase.

=head2 Functions

=over

=item C<setup()>

Sets the empty_test_case attribute to a new empty test case.

=item C<startup()>

Populates the selenese_data_files attribute with all of the found Selenese files.

=item C<constructor()>

Tests the various ways to construct a Parse::Selenese::TestCase.

=item C<tests_that_should_die()>

Tests the various ways a Parse::Selenese::TestCase should die.

=item C<tests_that_should_live()>

Tests the various ways a Parse::Selenese::TestCase should live.

=item C<test_each_stored_selenese_file()>

Test each file in C<selenese_data_files> in Selenese, Perl and YAML.

=item C<test_save_file()>

Test that we can actually save a Parse::Selenese::TestCase to a Selenese file.

=item C<test_new_from_content()>

Test that we can create a Parse::Selenese::TestCase from a string of content.

=back

=head1 AUTHOR

Theodore Robert Campbell Jr.  E<lt>trcjr@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
