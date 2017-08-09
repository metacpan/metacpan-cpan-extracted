package Pcore::Ext::Context::L10N;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr];

has ext => ( is => 'ro', isa => InstanceOf ['Pcore::Ext::Context'], required => 1 );
has is_plural => ( is => 'ro', isa => Bool, required => 1 );
has msgid     => ( is => 'ro', isa => Str,  required => 1 );
has domain    => ( is => 'ro', isa => Str,  required => 1 );
has msgid_plural => ( is => 'ro', isa => Maybe [Str] );
has num          => ( is => 'ro', isa => Maybe [Str] );

use overload    #
  q[""] => sub {
    return $_[0]->to_js->$*;
  },
  fallback => undef;

sub TO_JSON ( $self, @ ) {
    my $id = refaddr $self;

    $self->{ext}->{js_gen_cache}->{$id} = $self->to_js;

    return "__JS${id}__";
}

sub to_js ( $self ) {
    my $js;

    my $l10n_class_name = $self->{ext}->{ctx}->{l10n_class_name};

    # quote
    my $msgid  = $self->{msgid} =~ s/'/\\'/smgr;
    my $domain = $self->{domain} =~ s/'/\\'/smgr;

    if ( $self->{is_plural} ) {

        # quote $msgid_plural
        my $msgid_plural = $self->{msgid_plural} =~ s/'/\\'/smgr;

        my $num = $self->{num} // 1;

        $js = qq[$l10n_class_name.l10np('$msgid', '$msgid_plural', $num, '$domain')];
    }
    else {
        $js = qq[$l10n_class_name.l10n('$msgid', '$domain')];
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
