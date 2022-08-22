use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_code {
            use File::Spec::Functions;
            my $self = shift;
            $self->SUPER::ACTION_code(@_);
            # Copy the test scripts and then set the shebang line and make
            # sure that they're executable.
            my $to_dir = $self->localize_file_path("t/scripts");
            my $from   = $self->localize_file_path("t/bin/psql");
            my $to     = $self->localize_file_path("$to_dir/psql");
            $self->copy_if_modified(
                from    => $from,
                to_dir  => $to_dir,
                flatten => 1,
            );
            $self->fix_shebang_line($to);
            $self->make_executable($to);
            $self->add_to_cleanup($to_dir);
        }
        sub ACTION_tarball_name { print shift->dist_dir . ".tar.gz\n" }
        sub ACTION_latest_changes {
            my $self = shift;
            (my $dv = $self->dist_version) =~ s/^v//;
            open my $in, '<:raw', 'Changes' or die "Cannot open Changes: $!\n";
            open my $out, '>:raw', 'latest_changes.md' or die "Cannot open latest_changes.md: $!\n";
            while (<$in>) { last if /^\Q$dv\E\b/ }
            print {$out} "Changes for v$dv\n";
            while (<$in>) {
                last if /^\s*$/;
                chomp;
                if (s/^\s+-/-  /) {
                    print {$out} "\n";
                } else {
                    s/^\s+/ /;
                }
                print {$out} $_;
            }
            $self->add_to_cleanup('latest_changes.md');
        }
    },
);

$class->new(
    module_name        => 'TAP::Parser::SourceHandler::pgTAP',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => '0.30',
    },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.88',
    },
    requires => {
        'TAP::Parser::SourceHandler' => 0,
        'perl'                       => 5.006000,
    },
    recommends         => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge         => {
        resources => {
            homepage    => 'https://search.cpan.org/dist/Tap-Parser-Sourcehandler-pgTAP/',
            bugtracker  => 'https://github.com/theory/tap-parser-sourcehandler-pgtap/issues/',
            repository  => 'https://github.com/theory/tap-parser-sourcehandler-pgtap',
        }
    },
)->create_build_script;
