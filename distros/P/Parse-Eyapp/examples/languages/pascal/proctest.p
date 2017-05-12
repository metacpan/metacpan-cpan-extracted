program procTest (input, output);
 type arrreal5 = array [1..5] of real; 
 var a, b : integer;
     x : array [1..5] of real;

  procedure one (i, j : integer; k : arrreal5);
    var n : integer;
    begin
      n := i + j;
      k[n] := 2.345
    end;

  begin
    a := 1;
    b := 2;
    one(a,b,x);
    write(x[a+b])
  end.


