use Test::More;

use Path::Class::Iterator;

require "t/help.pl";

my $no_links = setup();

if ($no_links)
{
    plan tests => 2;
}
else
{
    plan tests => 3;
}

my $root    = 'test';
my $skipped = 0;

sub debug
{
    diag(@_) if $ENV{PERL_TEST};
}

ok(
    my $walker = Path::Class::Iterator->new(
        root          => $root,
        error_handler => sub {
            my ($self, $path, $msg) = @_;

            debug $self->error;
            debug "we'll skip $path";
            $skipped++;

            return 1;
        },
        follow_symlinks => 1,
        breadth_first   => 1
                                           ),
    "new object"
  );

my $count = 0;
until ($walker->done)
{
    my $f = $walker->next;

    $count++;
    if (-l $f)
    {
        debug "$f is a symlink";
    }
    elsif (-d $f)
    {
        debug "$f is a dir";
    }
    elsif (-f $f)
    {
        debug "$f is a file";
    }
    else
    {
        debug "no idea what $f is";
    }

}

ok($count > 1, "found some files");
debug "skipped $skipped files";
unless ($no_links)
{
    cmp_ok($skipped, '==', 2, "skipped bad links");
}

cleanup();
