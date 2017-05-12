# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/CVIC/Group.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::CVIC::Group;

use if $OurNet::BBS::Encoding, 'open' => ":encoding($OurNet::BBS::Encoding)";

use strict;
no warnings 'deprecated';
use fields qw/bbsroot bbsego brdobj group mtime _ego _hash/;
use OurNet::BBS::Base (
    'GroupGroup' => [qw/&_brdobj/],
);

sub writeok { 0 };
sub readok { 1 };

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    return unless $self->{group};

    if (!$key or index(' owner title id ', " $key ") > -1) {
	@{$self->{_hash}}{qw/owner title id/} = 
	    @{$self->{brdobj}}{qw/bm title id/};
	return 1 if $key;
    }

    my $file = "$self->{bbsroot}/group/$self->{group}";
    # return if $self->filestamp($file);

    my $GROUP;
    open($GROUP, "<$file") or open($GROUP, "+>>$file")
        or die("Cannot read group file $file: $!");

    my %remain = %{$self->{_hash} || {}};

    while ($key = <$GROUP>) {
        $key = $1 if $key =~ m/([\w\-\.]+)/;

        if (-e "$self->{bbsroot}/group/$key") {
            $self->{_hash}{$key} = $self->module('Group')->new(
                @{$self}{qw/bbsroot bbsego/}, $self->_brdobj($key), $key,
            );
	    delete $remain{$key};
        }
        elsif (substr($key, 0, 1) eq '+' and
               -e "$self->{bbsroot}/group/".($key = substr($key, 1))) {
            %{$self->{_hash}} = (
                %{$self->module('Group')->new( 
		    @{$self}{qw/bbsroot bbsego/}, $self->_brdobj($key), $key
		)},
                %{$self->{_hash}},
            );
        }
        elsif (-e "$self->{bbsroot}/boards/$key/.DIR") {
            $self->{_hash}{$key} = $self->module('Board')->new(
                $self->{bbsroot}, $key,
            );
	    delete $remain{$key};
        }
    }

    delete @{$self->{_hash}}{keys(%remain)};
    close $GROUP;
}

sub DELETE {
    my ($self, $key) = @_;
    $self = $self->ego;

    $self->refresh($key);
    return unless delete($self->{_hash}{$key});

    my $file = "$self->{bbsroot}/group/$self->{group}";
    open(my $GROUP, "<$file") or die "Cannot read group file $file: $!";
    my $content = join ('', grep { not m/\b$key\b/ } <$GROUP>);
    close $GROUP;

    open($GROUP, ">$file") or die "Cannot write group file $file: $!";
    print $GROUP $content;
    close $GROUP;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    my $file = "$self->{bbsroot}/group/$self->{group}";

    return if exists $self->{_hash}{$key}; # doesn't make sense yet

    die "doesn't exists such group or board $key: panic!"
        unless (-e "$self->{bbsroot}/group/$key" or
                -e "$self->{bbsroot}/boards/$key/.DIR");

    open(my $GROUP, ">>$file") or die "Cannot append group file $file: $!";
    print $GROUP $key, "\n";
    close $GROUP;
}

sub remove {
    my $self = shift;
    return unlink(join('/', $self->{bbsroot}, 'group', $self->{group}));
}

1;
