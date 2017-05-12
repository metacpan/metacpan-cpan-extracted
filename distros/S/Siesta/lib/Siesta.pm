# $Id: Siesta.pm 1435 2003-10-17 13:35:50Z richardc $
package Siesta;
use strict;
use vars qw/$VERSION $tt/;
$VERSION = '0.66';

use Siesta::List;
use Siesta::Message;

use IO::File;
use File::Find::Rule qw/find/;
use File::Basename qw/fileparse/;
use UNIVERSAL::require;
use Template;

use Carp qw(croak);

=head1 NAME

Siesta - the Siesta mailing list manager.

=head1 METHODS

=head2 ->new

=cut

sub new {
    my $referent  = shift;
    my %args = @_;
    my $class = ref $referent || $referent;

    my $storage = delete $args{storage};

    my $self = bless {}, $class;
    $self->log("instantiated a Siesta", 7);
    $self;
}

=head2 ->process( mail => $message, action => $action, list => $list )

process a mail

action may be C<post>, C<sub>, or C<unsub>
defaults to C<post>

mail must be either an anonymous array or a filehandle to read the
message body from

list must be the identifier of a mailing list

=cut


sub process {
    my $self   = shift;
    my %args   = @_;
    my $action = $args{action} || 'post';
    my $mail   = Siesta::Message->new( $args{mail} );
    my $list   = Siesta::List->load( $args{list} );

    $self->log("processing $action", 1);
    $mail->plugins( [ $list->plugins( $action ) ] );
    $mail->process;
}

my $sender;

=head2 ->sender

Return the current sender.

The default is Siesta::Send::Sendmail.

See B<set_sender> for other details.

=cut

sub sender {
    $sender || Siesta->set_sender('Sendmail');
}

=head2 ->set_sender ($class, @options)

Set the current sender to the given class.
This will pass on any options you give it automatically.

=cut

sub set_sender {
    my $self  = shift;
    my $class = shift;
    return unless $class;

    $class = "Siesta::Send::$class";
    $class->require
      or die "Couldn't require '$class': $UNIVERSAL::require::ERROR";
    $sender = $class->new(@_);
}

=head2 ->log ($message, $level)

Log message as long as level is below the value set in
I<$Siesta::Config::LOG_LEVEL>;

The lower the log level, the more important the error.

The default is 3.

=cut

my $logger;

sub log {
    my $self     = shift;
    my $message  = shift
      or croak "need a message to log";

    my $level = shift || $Siesta::Config::LOG_LEVEL;

    unless ($logger) {
        $logger = IO::File->new(">>$Siesta::Config::LOG_PATH")
          or die "Couldn't open file $Siesta::Config::LOG_PATH for appending\n";
    }

    my $date = localtime;
    print $logger "$date $message $level\n"
      if $level >= $Siesta::Config::LOG_LEVEL;
}


=head2 ->available_plugins

Return the name of every plugin on the system.

=cut

sub available_plugins {
    my $self = shift;
    my @dirs;

    foreach my $dir ( map { "$_/Siesta/Plugin" } @INC ) {
        push @dirs, $dir if ( -e $dir && -d $dir );
    }

    my @files = find( name => "*.pm", in => \@dirs );
    my @plugins;

    foreach my $file (@files) {
        my ($name) = fileparse($file, qr{\.pm});
        push @plugins, $name;
    }

    my %plugins = map { $_ => 1 } @plugins;

    return sort keys %plugins;
}

=head2 ->bake ( $template, $options )

$options, if present, is a hash reference

Returns the results of baking B<$template> with the variables
from B<$options> mixed in.

=cut

sub bake  {
    my $self     = shift;
    my $template = shift;

    my %opts = @_;

    $tt ||= Template->new({ INCLUDE_PATH => $Siesta::Config::MESSAGES });

    my $body;
    $tt->process($template, \%opts, \$body)
      or die "Couldn't process message template
                        '${Siesta::Config::ROOT}/messages/$template'
                        because : ",$tt->error();

    return $body;
}

=head1 COPYING

Licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<nacho>, L<tequila>, L<bandito>, L<Siesta::UserGuide>

=cut

1;

