# Example comparing results with Stanislav & Todorov (1999).

use Statistics::SDT 0.05;

my $sdt = Statistics::SDT->new(
  correction => 1,
  precision_s => 2,
 );

 $sdt->init(
  hits => 50,
  signal_trials => 50, # or misses => 0,
  false_alarms => 17,
  noise_trials => 25, # or correct_rejections => 8
 ); # or init these into 'new' &/or update any of their values as 2nd argument hashrefs in calling the following methods

 printf("Hit rate = %s\n",            $sdt->rate('h') );          #.99
 printf("False-alarm rate = %s\n",    $sdt->rate('f') );          # .68
 printf("Miss rate = %s\n",           $sdt->rate('m') );          # .00
 printf("Correct-rej'n rate = %s\n",  $sdt->rate('c'));           # .32
 printf("Sensitivity d' = %s\n",      $sdt->sens('d') );   		# 1.86
 printf("Sensitivity Ad' = %s\n",     $sdt->sens('Ad') );  		# 0.91
 printf("Sensitivity A' = %s\n",      $sdt->sens('A') ); 		# 0.82
 printf("Bias beta = %s\n",           $sdt->bias('b') );          # 0.07
 printf("Bias logbeta = %s\n",        $sdt->bias('log') );        # -2.60
 printf("Bias c = %s\n",              $sdt->bias('c') );          # -1.40
 printf("Bias Griers B'' = %s\n",     $sdt->bias('g') );          # -0.91
 printf("Criterion k = %s\n",         $sdt->criterion());         # -0.47
 printf("Hit rate via d & c = %s\n",  $sdt->dc2hr());             # .99
 printf("FAR via d & c = %s\n",       $sdt->dc2far());            # .68
 printf("LogBeta via d & c = %s\n",   $sdt->dc2logbeta());        # -2.60
 
 # If the number of alternatives is greater than 2, there are two options:
 printf("JAlex. d_fc = %s\n", $sdt->sensitivity('f' => {hr => .866, states => 3, correction => 0, method => 'alexander'})); # 2.00
 printf("JSmith d_fc = %s\n", $sdt->sensitivity('f' => {hr => .866, states => 3, correction => 0, method => 'smith'})); # 2.05
