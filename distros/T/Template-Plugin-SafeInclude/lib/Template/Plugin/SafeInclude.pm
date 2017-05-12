package Template::Plugin::SafeInclude;

use warnings;
use strict;

use parent qw/Template::Plugin/;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $context = shift;
    my $args = shift;

    my $self = bless {}, $class;
    $self->{_context} = $context;
    $self->{_verbose} = $args->{verbose};

    return $self;
}

sub inc {
    my $self = shift;
    my $path = shift;
    my $param = shift;
    
    my $html = "";
    eval {
        $html = $self->{_context}->include($path, $param);
    };
    unless ($@) {
	return $html;
    }
    if ($self->{_verbose}) {
	my $ret = sprintf "<!-- %s -->", $@;
	return $ret;
    }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Template::Plugin::SafeInclude - TT Plugin to safe include

=head1 SYNOPSIS

    [% USE SafeInclude %]
    [% SafeInclude.inc('your_include_file.html') %]

verbose mode.

    [% USE SafeInclude(verbose => 1) %]
    [% SafeInclude.inc('not_found_file.html') %]

output.

    <!-- file error - not_found_file.html: not found -->

with params.

    [% USE SafeInclude(verbose => 1) %]
    [% SafeInclude.inc('not_found_file.html', { foo => 1, bar => 2 }) %]

=head1 DESCRIPTION

=head2 verbose option

this module don't die even if template fail in including.

use the verbose option when you want to know include failure.

    [% USE SafeInclude(verbose => 1) %]
    <!-- file error - xxx.html: not found -->

when including succeeded, nothing is output.

=head1 METHODS

=head2 inc(path, params)

safe include.

=head1 SEE ALSO

L<Template>

=head1 AUTHOR

yuya matsumoto  C<< <yumatsumo at cpan.org> >>

=head1 THANKS TO

syushi matsumoto C<< <matsumoto at cpan.org> >>

