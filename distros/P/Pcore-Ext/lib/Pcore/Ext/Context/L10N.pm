package Pcore::Ext::Context::L10N;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr];

has ext          => ();
has domain       => ();
has msgid        => ();
has msgid_plural => ();
has num          => ();

use overload    #
  q[""] => sub {
    return $_[0]->to_js->$*;
  },
  q[&{}] => sub {
    my $self = $_[0];

    return sub { $self->to_js(@_)->$* };
  },
  fallback => undef;

sub TO_JSON ( $self ) {
    my $id = refaddr $self;

    $self->{ext}->{_js_gen_cache}->{$id} = $self->to_js;

    return "__JS${id}__";
}

sub to_js ( $self ) {
    my $js;

    # quote
    my $domain = $self->{domain} =~ s/'/\\'/smgr;
    my $msgid  = $self->{msgid} =~ s/'/\\'/smgr;

    if ( $self->{msgid_plural} ) {

        # quote $msgid_plural
        my $msgid_plural = $self->{msgid_plural} =~ s/'/\\'/smgr;

        my $num = $self->{num} // 1;

        $js = qq[Ext.L10N.l10n('$domain', '$msgid', '$msgid_plural', $num)];
    }
    else {
        $js = qq[Ext.L10N.l10n('$domain', '$msgid')];
    }

    return \$js;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Context::L10N - ExtJS function call generator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
