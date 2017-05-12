package Reply::Plugin::DataDumperAutoEncode;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.02";

use parent 'Reply::Plugin';

use Data::Dumper;
use Data::Dumper::AutoEncode;

my $enable_auto_encode = 1;

sub new {
    my $class = shift;

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Sortkeys = 1;

    my @subs = ('enable_auto_encode', 'disable_auto_encode');
    for my $sub_name ( @subs ) {
        no strict 'refs';
        *{ 'main::' . $sub_name } = \&{ $sub_name };
    }

    return $class->SUPER::new( @_, subs => \@subs );
}

sub mangle_result {
    my $self = shift;
    my (@result_in) = @_;

    my @result = @result_in == 0 ? () : @result_in == 1 ? $result_in[0] : \@result_in;
    if ( $enable_auto_encode ) {
        return eDumper(@result);
    }
    else {
        return Dumper(@result);
    }
}

sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    return if length $line <= 0; 
    return if $line =~ /^#/; # command
    return if $line =~ /->\s*$/; # method call
    return if $line =~ /[\$\@\%\&\*]\s*$/;

    return sort grep { index($_, $line) == 0 } @{ $self->{subs} };
}

sub enable_auto_encode  { $enable_auto_encode = 1; }
sub disable_auto_encode { $enable_auto_encode = 0; }



1;
__END__

=encoding utf-8

=head1 NAME

Reply::Plugin::DataDumperAutoEncode - format and decode results using Data::Dumper::AutoEncode

=head1 SYNOPSIS

    ; in your .replyrc use following instead of [DataDumper]
    [DataDumperAutoEncode]

=head1 DESCRIPTION

Reply::Plugin::DataDumperAutoEncode uses L<Data::Dumper::AutoEncode> to format and encode results.
Results of L<Data::Dumper> has decoded string, it is hard to read for human. Using this plugin
instead of L<Reply::Plugin::DataDumper>, results are automatically decoded and easy to read for human.

=head1 METHODS

=head2 enable_auto_encode()

enables auto encode. auto encode is enabled by default.

=head2 disable_auto_encode()

disables auto encode

=head1 SEE ALSO

L<Reply::Plugin::DataDumper>, L<Data::Dumper::AutoEncode>

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

