
use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::Task' => {
    qw(name        $
       begin_time  $
       end_time    $),
    '&as_xml' => q!
    
    return qq(<taskbegin task="$name" time="$begin_time"/>\n) .
           qq(<taskend task="$name" time="$end_time"/>\n);

    !
};

=pod

=head1 DESCRIPTION

This class represents Nmap live task status messages (taskend and 
taskbegin elements in XML).

=head1 PROPERTIES

=head2 name()

=head2 begin_time()

=head2 end_time()

=cut

1;
