package ShipIt::Step::CommitMessageWrap;
use strict;
use warnings;
use base 'ShipIt::Step';
our $VERSION = '0.04';

sub init {
    my ($self, $conf) = @_;

    $self->{format} = $conf->value('commit_message.format') || '%msg';
    $self->{format} =~ s/%/%%/g;
    $self->{format} =~ s/%%msg/%s/g;
}

sub run {
    my ($self, $state) = @_;

    my $pkg = ref($state->vc);

    my $commit      = $pkg->can('commit');
    my $tag_version = $pkg->can('tag_version');
    no strict 'refs';
    *{"$pkg\::commit"} = sub {
        use strict;
        my $c = shift;
        my $msg  = shift;
        $msg = sprintf $self->{format}, $msg;
        $commit->($c, $msg, @_);
    };
    *{"$pkg\::tag_version"} = sub {
        use strict;
        my $c = shift;
        my $ver  = shift;
        my $msg  = shift;
        $msg = sprintf $self->{format}, $msg;
        $tag_version->($c, $ver, $msg, @_);
    };
    use strict;
}

1;
__END__

=head1 NAME

ShipIt::Step::CommitMessageWrap - commit message wrapping format to shipit version control

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

this module is quick hack to commit and tag_version method in ShipIt::VC module.
commit message it makes your free wrapping format to version control.

=head1 CONFIGURATION

In the .shipit file:

  commit_message.format = before %msg after

tagging log:

  before Tagging version '$ver' using shipit. after

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
