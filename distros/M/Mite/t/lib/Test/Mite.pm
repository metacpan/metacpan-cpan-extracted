{
    package Test::Mite;

    use feature ':5.10';
    use strict;
    use warnings;

    use parent 'Fennec';
    use Path::Tiny;

    # func, not a method, to avoid altering @_
    sub import {
        # Turn on strict, warnings and 5.10 features
        strict->import;
        warnings->import;
        require feature;
        feature->import(":5.10");

        # Make everything in @INC absolute so we can chdir in tests
        @INC = map { path($_)->absolute->stringify } @INC;

        #push @_, test_sort => 'ordered';
        goto &Fennec::import;
    }

    # Export our extra mite testing functions.
    sub defaults {
        my $class = shift;
        my %params = $class->SUPER::defaults;

        push @{ $params{utils} },
          "Test::Mite::Functions",
          "Test::Deep",
          "Test::FailWarnings";

        return %params;
    }

    # Test with and without Class::XSAccessor.
    sub after_import {
        my ($class, $info) = (shift, @_);
        return unless $info->{meta}{with_recommends};

        # Test the pure Perl implementation.
        $info->{layer}->add_case(
            [$info->{importer}, __FILE__, __LINE__ + 1],
            case_pure_perl => sub {
                $ENV{MITE_PURE_PERL} = 1;
            },
        );

        # Test with Class::XSAccessor, if available.
        $info->{layer}->add_case(
            [$info->{importer}, __FILE__, __LINE__ + 1],
            case_xs => sub {
                $ENV{MITE_PURE_PERL} = 0;
            },
        ) if eval { require Class::XSAccessor };
    }
}


# Because of the way Fennec works, it's easier to put
# all our extra functions into their on class.
{
    package Test::Mite::Functions;

    use feature ':5.10';
    use strict;
    use warnings;

    use parent 'Exporter';
    our @EXPORT = qw(
        mite_compile mite_load
        sim_source sim_class sim_project sim_attribute
        rand_class_name
        mite_command
        make
        env_for_mite
    );

    use Test::Sims;
    use Path::Tiny;
    use Child;

    use utf8;
    make_rand class_word => [qw(
        Foo bar __9 h1N1 CAPITAL
    )];

    make_rand evil_class_word => [qw(
        Foo bar __9 h1N1 ünicode
    )];

    sub rand_method_name {
        return rand_evil_class_word();
    }

    my $max_class_words = 5;
    make_rand class_name => sub {
        my $num_words = (int rand $max_class_words) + 1;
        return join "::", map { rand_class_word() } (1..$num_words);
    };

    # Because some things are stored as weak refs, automatically created
    # sim objects can be deallocated if we don't hold a reference to them.
    sub _store_obj {
        my $obj = shift;
        state $storage = [];

        push @$storage, $obj;

        return $obj;
    }

    sub sim_class {
        my (%args) = @_;
        $args{name}   //= rand_class_name();
        $args{source} //= _store_obj( sim_source(
            class_name  => $args{name}
        ));

        return $args{source}->class_for($args{name});
    }

    sub sim_source {
        my (%args) = @_;
        # Keep all the sources in one directory simulating a
        # project library directory
        state $source_dir = Path::Tiny->tempdir;

        my $class_name = delete $args{class_name} || rand_class_name();

        my $default_file = $source_dir->child(_class2pm($class_name));
        $default_file->parent->mkpath;
        $default_file->touch;
        $args{file} //= $default_file;

        # Put everything in the same project, much more useful for testing.
        require Mite::Project;
        $args{project} //= Mite::Project->default;

        return $args{project}->source_for($args{file});
    }

    sub sim_project {
        my (%args) = @_;
        require Mite::Project;
        return Mite::Project->new;
    }

    make_rand "attr_default" => [(
        0, 1, "Foo", sub { [] }
    )];

    make_rand "attr_is" => [qw(ro rw)];

    sub set_sometimes {
        my ($thing, $key, $func, $when) = @_;
        $when //= 2;
        return unless int rand $when;

        $thing->{$key} //= $func->();

        return;
    }

    sub sim_attribute {
        my (%args) = @_;
        $args{name} //= rand_method_name;
        set_sometimes(\%args, "is", \&rand_attr_is);
        set_sometimes(\%args, "default", \&rand_attr_default);

        require Mite::Attribute;
        return Mite::Attribute->new( %args );
    }

    sub _class2pm {
        my $class = shift;
        my $pm = $class.'.pm';
        $pm =~ s{::}{/}g;

        return $pm;
    }

    sub mite_compile {
        my $code = shift;
        # Write the code to a temp file, make sure it survives this routine.
        my $file = Path::Tiny->tempfile( UNLINK => 0 );
        $file->spew_utf8($code);

        # Compile the code
        # Do it in its own process to avoid polluting the test process
        # with compiler code.  This better emulates how it works in production.
        run_in_child(sub {
            require Mite::Project;
            my $project = Mite::Project->default;
            $project->load_files([$file]);
            $project->write_mites;
        });

        return $file;
    }

    sub mite_load {
        my $code = shift;
        my $file = mite_compile($code);

        # Allow the same file to be recompiled and reloaded
        do $file;

        return $file;
    }

    sub run_in_child {
        my $code = shift;
        # Avoid polluting the testing environment
        my $child = Child->new($code);

        my $process = $child->start;
        $process->wait;

        if( my $child_exit = $process->exit_status ) {
            die "Compiling returned exit code $child_exit";
        }

        return $process;
    }

    sub mite_command {
        my @args = @_;
        return run_in_child(sub {
            require Mite::App;
            my $app = Mite::App->new;
            $app->execute_command( $app->prepare_command(@args) );
        });
    }

    sub make {
        require Config;

        my $make = $Config::Config{make};
        $make = $ENV{MAKE} if exists $ENV{MAKE};
        $make //= 'make';

        return $make;
    }

    sub env_for_mite {
        my $libdir = path("lib")->absolute;
        my $bindir = path("bin")->absolute;

        $ENV{MITE} = "$^X $bindir/mite";
        $ENV{PERL5LIB} = join ':', grep { defined } $libdir, $ENV{PERL5LIB};

        return;
    }

    # We're loaded, really!
    $INC{"Test/Mite/Functions.pm"} = __FILE__;
}

1;
