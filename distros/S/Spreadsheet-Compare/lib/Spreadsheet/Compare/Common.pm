package Spreadsheet::Compare::Common;

use Mojo::Base -strict, -signatures;
use Mojo::Util qw(monkey_patch);
use Module::Load qw(load_remote autoload_remote);
use Class::Method::Modifiers qw(install_modifier);
use Log::Log4perl qw(:easy);
use Carp;
use YAML::Any qw(Dump);
use Path::Tiny qw(path tempdir);

sub attr {
    my( $self, $attrs, $value, %kv ) = @_;

    my $ro = delete $kv{ro};
    return Mojo::Base::attr( $self, $attrs, $value, %kv ) unless $ro;

    $attrs = [$attrs] unless ref($attrs) eq 'ARRAY';
    my $class = ref $self || $self;
    for my $attr (@$attrs) {
        my $ro_attr = '__ro__' . $attr;
        Mojo::Base::attr( $self, $ro_attr, $value, %kv );
        my $sub = sub {
            croak qq(attribute "$attr" is readonly)                if @_ > 1;
            carp qq(found rw value for readonly attribute "$attr") if exists $_[0]->{$attr};
            return $_[0]->$ro_attr;
        };
        monkey_patch( $class, $attr, $sub );
    }
    return;
}


sub import ( $class, %args ) {
    my $pkg = caller;

    require experimental;
    experimental->import(qw(postderef lexical_subs));

    load_remote $pkg, 'Path::Tiny',    qw(cwd path tempfile tempdir);
    load_remote $pkg, 'YAML::Any',     qw(Dump Load DumpFile LoadFile);
    load_remote $pkg, 'Log::Log4perl', ':easy';
    load_remote $pkg, 'List::Util',    qw(any max none pairgrep pairmap reduce);
    load_remote $pkg, 'POSIX',         qw(strftime);

    autoload_remote $pkg, 'Carp';
    autoload_remote $pkg, 'Try::Tiny';

    if ( $args{test} ) {
        load_remote $pkg, 'Mojo::Base',   qw( -strict -signatures);
        load_remote $pkg, 'Mojo::Loader', qw(data_section);
        load_remote $pkg, 'FindBin',      qw($Bin $Script);
        load_remote $pkg, 'Module::Load', qw(load autoload);

        autoload_remote $pkg, 'Test::More';
        autoload_remote $pkg, 'Test::Exception';

        my $pt = path('t');
        if ( $args{temp} and $pt->is_dir ) {
            my $fn   = path($0)->basename('.t');
            my $tmpd = tempdir(
                DIR      => 't',
                CLEANUP  => $ENV{SPREADSHEET_COMPARE_CLEANUP} // $pt->sibling('.idea')->is_dir,
                TEMPLATE => "${fn}_XXXX",
            );
            monkey_patch( $pkg, 'tmpd', sub { $tmpd } );
            $ENV{SC_TMPD} = $tmpd->absolute;
        }

        return;
    }

    install_modifier(
        $pkg, 'around', 'new',
        sub {
            my $orig = shift;
            my $self = $orig->(@_);
            for my $attr ( keys %$self ) {
                croak qq(attribute "$attr" is readonly\n) if $self->can( '__ro__' . $attr );
            }
            $self->init() if $self->can('init');
            return $self;
        },
    );

    monkey_patch( $pkg, 'has', sub { attr( $pkg, @_ ) } );

    monkey_patch(
        $pkg,
        'get_log_settings',
        sub {
            my $logger = Log::Log4perl->get_logger('');
            return $logger->is_trace, $logger->is_debug;
        }
    );

    monkey_patch(
        $pkg,
        'call_stack',
        sub {
            my $trace = '';
            for my $lev ( 0 .. 9 ) {
                my( $package, $file, $line ) = caller($lev);
                next unless $line;
                $trace .= "$package, at $file line $line\n";
            }
            return $trace;
        }
    );

    return;
}


1;


=head1 NAME

Spreadsheet::Compare::Common - convenient imports for Spreadsheet::Compare Modules

=head1 DESCRIPTION

This module injects various Modules and functions into the namespace of the caller:

=over 4

=item * L<Carp|https://metacpan.org/pod/Carp>

=item * L<Try::Tiny|https://metacpan.org/pod/Try::Tiny>

=item * C<cwd>, C<path>, C<tempfile>, C<tempdir> from L<Path::Tiny|https://metacpan.org/pod/Path::Tiny>

=item * C<Dump>, C<Load>, C<DumpFile>, C<LoadFile> from L<YAML|https://metacpan.org/pod/YAML>

=item * L<Log::Log4perl|https://metacpan.org/pod/Log::Log4perl> in easy mode

=item * C<any>, C<max>, C<none>, C<pairgrep>, C<pairmap>, C<reduce> from L<List::Util|https://metacpan.org/pod/List::Util>

=item * C<strftime> from L<POSIX|https://metacpan.org/pod/POSIX>

=back

In addition it enables the postderef feature and extends the C<has> function of
L<Mojo::Base|https://metacpan.org/pod/Mojo::Base>
with an C<ro> option to specify that the attribute is readonly, e.g.:

    use Mojo::Base -base, -signatures;
    use Spreadsheet::Compare::Common;

    has thing => 42, ro => 1;

If the module is loaded with the "test" option set to a true value,

    use Spreadsheet::Compare::Common test => 1;

    ... use test functions

it will additionally inject the following:

=over 4

=item * L<Mojo::Base|https://metacpan.org/pod/Mojo::Base> with C<-strict> and C<-signatures>

=item * L<Test::More|https://metacpan.org/pod/Test::More>

=item * L<Test::Exception|https://metacpan.org/pod/Test::Exception>

=item * C<data_section> from L<Mojo::Loader|https://metacpan.org/pod/Mojo::Loader>

=item * C<$Bin> and C<$Script> from L<FindBin|https://metacpan.org/pod/FindBin>

=back

The test option can be extended with a "temp" option. This will create a temporary directory
in the "t" directory starting with the test file name. (e.g. t/01_base_V3CQ for t/01_base.t).
By default it will be cleaned up afterwards. To keep the directory set the environment variable
C<SPREADSHEET_COMPARE_CLEANUP> to a true value. The absolute name of the temp directory will
be available in the environment variable C<SC_TMPD>

    use Spreadsheet::Compare::Common test => 1, temp => 1;

    ... save temp data to $ENV{SC_TMPD}


=cut
