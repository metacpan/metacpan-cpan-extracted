package TestC;
use Spoon '-Base';
use Spoon::Installer '-mixin';

__DATA__

__t/output/file1.html__
<hr>
__t/output/file2.html__
<!-- BEGIN bogus -->
<hr>
<!-- END bogus -->
__t/output/file3.html__
 <hr>
__t/output/file4.html__
<hr> 
__t/output/file5.html__
 <hr>

