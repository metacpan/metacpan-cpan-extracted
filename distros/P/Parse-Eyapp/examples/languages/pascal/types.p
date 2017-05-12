program Types;
 
Type
   StudentRecord = Record
      Number: Integer;
      Name: String;
   end;
 
var
   Student: StudentRecord;
 
begin
   Student.Number := 12345;
   Student.Name := 'John Smith';
end. 
