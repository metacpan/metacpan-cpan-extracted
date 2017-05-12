use warnings;
use strict;

package SVN::Ra;

our @new_params;
sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->initialize('orig_params' => [@_], @new_params);

    return $self;
}

sub initialize
{
    my $self = shift;

    my (%args) = (@_);

    $self->{'orig_params'} = $args{'orig_params'};

    $self->{'get_latest_revnum'} = $args{'get_latest_revnum'} ||
        sub {
            return 100;
        }
        ;

    $self->{'check_path'} = $args{'check_path'} ||
        sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if (($path =~ /NA\{\}/) || ($path =~ /NA\{$rev_num\}/))
            {
                return undef;
            }
            elsif ($path =~ m{\.[^/]*$})
            {
                return $SVN::Node::file;
            }
            else
            {
                return $SVN::Node::dir;
            }
        };

    $self->{'get_dir'} = $args{'get_dir'} || sub {
        my $self = shift;
        my $path = shift;
        my $rev_num = shift;

        return
            (
                {
                    'Hello.pm' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'mydir' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                },
                $rev_num
            );
    };

    $self->{'get_file'} = $args{'get_file'};
}

sub get_latest_revnum
{
    my $self = shift;
    return $self->{'get_latest_revnum'}->($self, @_);
}

sub check_path
{
    my $self = shift;
    return $self->{'check_path'}->($self, @_);
}

sub get_dir
{
    my $self = shift;
    my ($dir_contents, $fetched_rev) = $self->{'get_dir'}->($self, @_);
    return
        (+{
            map
            {
                $_ =>
                    SVN::RaWeb::Light::Mock::DirEntry->new($_, $dir_contents->{$_})
            }
            keys(%$dir_contents)
        }, $fetched_rev);
}

sub get_file
{
    my $self = shift;

    return $self->{'get_file'}->($self,@_);
}

BEGIN
{
    $INC{'SVN/Ra.pm'} = '/usr/lib/perl5/site_perl/5.8.6/i386-linux/SVN/Ra.pm';
    $INC{'SVN/Core.pm'} = '/usr/lib/perl5/site_perl/5.8.6/i386-linux/SVN/Core.pm';
}

$SVN::Node::dir = "dir";
$SVN::Node::file = "file";
$SVN::Node::none = "notexist";
$SVN::Node::unknown = "unknown";

package SVN::RaWeb::Light::Mock::DirEntry;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

sub initialize
{
    my $self = shift;
    my $filename = shift;
    my $params = shift;
    $self->{'filename'} = $filename;
    $self->{'kind'} = $params->{'kind'};
    return 0;
}

sub kind
{
    my $self = shift;
    return $self->{'kind'};
}

1;


1;

