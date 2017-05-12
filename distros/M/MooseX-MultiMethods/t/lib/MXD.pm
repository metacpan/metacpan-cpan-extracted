use MooseX::Declare;

class Scissor;
class Stone;
class Paper;

class ScissorStonePaper {
    use MooseX::MultiMethods;
    
    multi method play ( Scissor $x, Paper   $y ) { 1 }
    multi method play ( Stone   $x, Scissor $y ) { 1 }
    multi method play ( Paper   $x, Stone   $y ) { 1 }
    multi method play ( Any     $x, Any     $y ) { 0 }
}

1;
