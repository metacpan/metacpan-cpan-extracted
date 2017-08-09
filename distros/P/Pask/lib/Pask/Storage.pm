package Pask::Storage;

use utf8;
use open ':std', ':encoding(UTF-8)';
use Term::ANSIColor;
use Carp;

use Pask::Container;

my $types = {
    -success => { color => "green on_bright_white", output => ["FILE", "TERM"], note => "Success"},
    -info => { color => "cyan on_bright_white", output => ["FILE", "TERM"], note => "Info" },
    -log => { color => "black on_bright_white", output => ["FILE", "TERM"], note => "Log" },
    -warn => { color => "yellow on_bright_white", output => ["FILE", "TERM"], note => "Warn" },
    -debug => { color => "red on_bright_white", output => ["FILE", "TERM"], note => "Debug" },
    -title => { color => "bright_white on_green", output => ["TERM"], note => "Title" },
    -description => { color => "bright_white on_magenta", output => ["TERM"], note => "Description"},
    -system => { color => "bright_white on_white", output => ["FILE", "TERM"], note => "System" },
    -error => { color => "bright_white on_red", output => ["TERM"], note => "Error" }
};

sub get_all_type_name {
    keys %$types;
}

sub init_log_handle {
    my $file = Pask::Container::get_log_file;
    open my $file_handle, ">> $file" or Carp::confess "can not write log to $file";
    Pask::Container::set_log_handle $file_handle;
}

sub register_all {
    foreach my $type_name (get_all_type_name) {
        Pask::Container::set_storage($type_name, new Pask::Storage({
            type => $type_name,
            color => $types->{$type_name}{"color"},
            output => $types->{$type_name}{"output"}
        }));
    }
}

sub say {
    my ($type, $message, $type_name) = (shift, shift);
    $message = "" unless $message;
    unless (ref $type) {
        $message = $type . $message;
        $type = {"-log"};
    }
    $type_name = (keys %$type)[0];
    $type_name = "-log" unless grep /^$type_name$/, get_all_type_name;
    Pask::Container::get_storage($type_name)->annotate($message, @_);
}

sub notice {
    say {"-system"}, @_;
}

sub error {
    my $file_handle = Pask::Container::get_log_handle;
    say {"-error"}, @_;
    print $file_handle "--- Task End ---\n\n";
    Carp::croak "";
}

# todo serialize/unserialize
sub memory {
}

### instance ###

sub new {
    shift;
    bless shift;
}

sub annotate {
    use POSIX qw (strftime);
    my $this = shift;
    my $note_suffix = "";
    my ($flag1, $flag2) = @{$this->{"output"}};
    my ($is_to_file, $is_to_term) = (undef, undef);
    $is_to_file = ($flag1 eq "FILE" or $flag2 eq "FILE");
    $is_to_term = ($flag1 eq "TERM" or $flag2 eq "TERM");
    do {
        $note_suffix = "@" . strftime("%Y-%m-%d %H:%M:%S", localtime) if ($this->{"type"} eq "-info" or $this->{"type"} eq "-log" or $this->{"type"} eq "-warn" or $this->{"type"} eq "-debug" or $this->{"type"} eq "-success");
        print colored [$types->{-system}{"color"}], "[", $types->{$this->{"type"}}{"note"}, $note_suffix, "]";
        print " ";
        print colored [$this->{"color"}], @_;
        print color "reset";
        print "\n";
    } if $is_to_term;
    do {
        $note_suffix = "@" . strftime("%H:%M:%S", localtime) if ($this->{"type"} eq "-info" or $this->{"type"} eq "-log" or $this->{"type"} eq "-warn" or $this->{"type"} eq "-debug" or $this->{"type"} eq "-success");
        my $file_handle = Pask::Container::get_log_handle;
        print $file_handle "[", $types->{$this->{"type"}}{"note"}, $note_suffix, "] ", @_, "\n";
    } if $is_to_file;
}

1;
