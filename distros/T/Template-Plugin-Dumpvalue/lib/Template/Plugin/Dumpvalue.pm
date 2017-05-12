package Template::Plugin::Dumpvalue;

use base qw(Template::Plugin);

use Dumpvalue;
use IO::Scalar;
use strict;

our $VERSION = 1.01;

sub new {
    my $class = shift;
    my $context = shift;
    my $hash = shift;

    my $d = Dumpvalue->new();

    my $self = {
        d => $d,
        stash => $context->{STASH},
        output => '',
    };

    bless $self, $class;

    $self->set($hash);

    return $self;
}

sub dump_template_vars {
    my $self = shift;

    return $self->dumpValue($self->{stash});
}

sub grab_output {
    my $self = shift;
    my $code = shift;


    my $output;
    tie *DUMP, 'IO::Scalar', \$output;

    my $old_fh = select(DUMP);

    &{$code};

    select($old_fh);

    if($self->{inHTML}) {
        $output =~ s/</&lt;/g;
        $output =~ s/>/&gt;/g;
        $output = "<pre>$output</pre>";
    }

    return $output;
}

sub dumpValue {
    my $self = shift;
    my $dump = shift;

    return $self->grab_output( sub {
        $self->{d}->dumpValue(\$dump);
    });
}

sub dumpValues {
    my $self = shift;
    my @values = @_;

    return $self->dumpValue(\@values);
}

sub dumpvars {
    my $self = shift;
    my @args = @_;

    return $self->grab_output( sub {
        $self->{d}->dumpvars(@args);
    });
}

sub set {
    my $self = shift;
    my $hash = shift;

    if(exists($hash->{inHTML})) {
        $self->{inHTML} = delete $hash->{inHTML};
    }

    $self->{d}->set(%$hash);

    return '';
}

sub get {
    my $self = shift;
    my @array = @_;

    my @values = $self->{d}->get(@array);

    return @values;
}

sub stringify {
    my $self = shift;

    return $self->{d}->stringify(@_);
}

sub compactDump {
    my $self = shift;

    $self->{d}->compactDump(@_);
    return;
}

sub veryCompact {
    my $self = shift;

    $self->{d}->veryCompact(@_);
    return;
}

sub set_quote {
    my $self = shift;

    $self->{d}->set_quote(@_);
    return;
}

sub set_unctrl {
    my $self = shift;

    $self->{d}->set_unctrl(@_);
    return;
}

1;

__END__

=head1 NAME

Template::Plugin::Dumpvalue - Interface to Dumpvalue through the Template Toolkit

=head1 SYNOPSIS

 [% USE d = Dumpvalue %]
 [% hash = {
      a => 1,
      b => 2,
      c => 3
    } %]
 [% d.dumpValue(hash) %]
 [% d.dump_template_vars() %]

=head1 DESCRIPTION

This module gives access to Dumpvalue's powerful debugging capabilities.
Provides all the methods and options that Dumpvalue has with a little extra.

=over 4

Extra option:

=over 4

inHTML

=over 4

Can be set in the constructor or with the method I<set()>. Setting the inHTML 
option  to 1 (i.e. [% d.set(inHTML => 1) %]) will surround the dump with <pre></pre> 
tags and replace <, and > with &lt; and &gt; so it looks nice in HTML.

=back

=back

Extra method:

=over 4

dump_template_vars(),

=over 4

Dumps the template's stash.

=back

=back

=back

=head1 SEE ALSO

Dumpvalue

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
