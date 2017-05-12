package Progress::Any::Output::TermMessage;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.02'; # VERSION

sub new {
    my ($class, %args0) = @_;

    my %args;

    $args{template}          = delete($args0{template}) // "(%P/%T) %m";
    $args{single_line_task}  = delete($args0{single_line_task}) // 0;

    keys(%args0) and die "Unknown output parameter(s): ".
        join(", ", keys(%args0));

    bless \%args, $class;
}

sub update {
    my ($self, %args) = @_;

    my $p = $args{indicator};

    my $s = $p->fill_template($self->{template}, %args);
    $s =~ s/\r?\n//g;

    if ($self->{single_line_task}) {
        if (defined($self->{prev_task}) && $self->{prev_task} ne $p->{task} ||
            $p->{finished}) {
            print "\n";
        } elsif (defined $self->{prev_task}) {
            print "\b" x length($self->{prev_str});
        }
    }
    print $s;
    print "\n" if !$self->{single_line_task} || $p->{finished};

    if ($p->{finished}) {
        undef $self->{prev_task};
        undef $self->{prev_str};
    } else {
        $self->{prev_task} = $p->{task};
        $self->{prev_str}  = $s;
    }
}

1;
# ABSTRACT: Output progress to terminal as simple message

__END__

=pod

=head1 NAME

Progress::Any::Output::TermMessage - Output progress to terminal as simple message

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Progress::Any::Output;
 Progress::Any::Output->set('TermMessage', template=>"[%n] (%P/%T) %m");

=head1 DESCRIPTION

This output displays progress indicators as messages on terminal.

=for Pod::Coverage ^(update)$

=head1 METHODS

=head2 new(%args) => OBJ

Instantiate. Usually called through C<<
Progress::Any::Output->set("TermMessage", %args) >>.

Known arguments:

=over

=item * template => STR (default: '(%P/%T) %m')

Will be used to do C<< $progress->fill_template() >>. See L<Progress::Any> for
supported template strings.

=item * single_line_task => BOOL (default: 0)

If set to true, will reuse line using a series of C<\b> to get back to the
original position, as long as the previous update is for the same task and the
C<finished> attribute is false. For example:

 use Progress::Any;
 use Progress::Any::Output;

 Progress::Any::Output->set("TermMessage",
     single_line_task=>0, template=>"%t %m");
 my $progress = Progress::Any->get_indicator(
     task => 'copy', title => 'Copying file ... ');
 $progress->update(message=>'file1.txt');
 $progress->update(message=>'file2.txt');
 $progress->update(message=>'file3.txt');
 $progress->finish(message=>'success');

will result in:

 Copying file ... file1.txt_
 Copying file ... file2.txt_
 Copying file ... file3.txt_
 Copying file ... success
 _

all in one line.

=back

=head1 SEE ALSO

L<Progress::Any>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
