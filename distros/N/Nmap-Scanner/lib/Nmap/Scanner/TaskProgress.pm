
use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::TaskProgress' => {
    qw(task        Nmap::Scanner::Task
       time        $
       percent     $
       remaining   $
       etc         $),
    '&as_xml' => q!
    
    my $name = $task->name();

    return qq(<taskprogress task="$name" time="$time"/>) .
           qq(percent="$percent" remaining="$remaining" etc="$etc"/>\n);

    !
};

=pod

=head1 DESCRIPTION

This class represents Nmap live task status messages; note that the
included Nmap::Scanner::Task reference will not have an end_time()
attribute as the task has not ended yet ;).

=head1 PROPERTIES

=head2 task()

Reference to Nmap::Scanner::Task instance

=head2 time()

Time this progress event occurred.

=head2 percent()

Percent of this task done.

=head2 remaining()

Percent of this task left to do.

=head2 etc()

Estimated time to complete for this task.

=cut

1;
