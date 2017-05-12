use ExtUtils::MakeMaker;    
WriteMakefile(                                                         
    'NAME'              => 'PDL::RungeKutta',                                
    'VERSION'           => '0.01',                                     
    ($] >= 5.005 ?                                                     
     (ABSTRACT => 'Adaptive stepsize Runge Kutta integrator', 
      AUTHOR   => 'Dragos Constantinescu <dragos@venus.nipne.ro>') : ()),       
    'PREREQ_PM'         => { 'PDL' => 2.40 },                    
);                                                                     
