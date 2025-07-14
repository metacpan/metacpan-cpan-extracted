use Mojo::File qw/path/;
use File::HomeDir;
use Test::More;

my $user = getlogin() || $ENV{USER} || $ENV{LOGNAME} || getpwuid($<);

my $p = path()->with_roles("+HomeDir");

my @subs = qw/
    my_home
    my_desktop
    my_documents
    my_music
    my_pictures
    my_videos
    my_data
    my_dist_config
    my_dist_data
    users_home
    users_documents
    users_data
    users_desktop
    users_music
    users_pictures
    users_videos
    /;
for my $sub (grep { /^my/ && !/^my_dist/} @subs) {
    SKIP: {
        my $expected = eval { File::HomeDir->$sub };
        if ($@ || !defined $expected) {
            skip("'$sub' $@" =~ s/\ at.+//mrs, 1);
            next;
        }
        ok($p->$sub eq $expected, $sub);
    }
}

for my $sub (grep { /^users/ } @subs) {
    SKIP: {
        my $expected = eval { File::HomeDir->$sub($user) };
        if ($@ || !defined $expected) {
            skip("'$sub' $@" =~ s/\ at.+//mrs, 1);
            next;
        }
        ok($p->$sub($user) eq $expected, "$sub(\$user)");
    }
}


done_testing()
