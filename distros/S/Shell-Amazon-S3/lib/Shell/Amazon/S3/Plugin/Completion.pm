package Shell::Amazon::S3::Plugin::Completion;
use strict;
use Shell::Amazon::S3::Plugin;
use Scalar::Util 'weaken';
use namespace::clean -except => ['meta'];

sub BEFORE_PLUGIN {
    my ($self) = @_;

    my $weakself = $self;
    weaken($weakself);

    $self->term->Attribs->{completion_function} = sub {
        $weakself->_completion(@_);
    };
}

sub _completion {
    my ( $self, $text, $line, $start, $end ) = @_;

    my @command_list = qw(
        bucket count createbucket delete deleteall deletebucket
        exit get getfile getacl gettorrent head host help list listbuckets listatom
        listrss pass put putfile putfilewacl quit setacl user
    );

    my @matched = grep { $_ =~ /^$text/ } @command_list;
    return @matched;
}

sub complete {
    return ();
}

1;

