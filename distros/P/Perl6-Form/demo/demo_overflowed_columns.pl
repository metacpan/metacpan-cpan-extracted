use Perl6::Form;

$name = "William Shakespeare";

$status = "Deceased (1564-1616)";

$comments = "Theories abound as to the true author of his plays. The prime
alternative candidates being Sir Francis Bacon, Christopher Marlowe, or 
Edward de Vere";

$bio = <<EOBIO;
William Shakespeare was born on April 23, 1564 in Strathford-upon-Avon, England; he was third of eight children from Father John Shakespeare and Mother Mary Arden. Shakespeare began his education at the age of seven were he probably attended the Strathford grammar school. The school provided Shakespeare with his formal education. The students chiefly studied Latin rhetoric, logic, and literature. His knowledge and imagination may have come from his reading of ancient authors and poetry. In November 1582, Shakespeare received a license to marry Anne Hathaway. At the time of their marriage, Shakespeare was 18 years old and Anne was 26. They had three children, the oldest Susanna, and twins- a boy, Hamneth, and a girl, Judith. Before his death on April 23 1616, William Shakespeare had written Thirty-seven plays. He is generally considered the greatest playwright the world has ever known and has always been the world's most popular author.
EOBIO

print form
	"Name:				                                   ",
	"  {[[[[[[[[[[[[}                                      ", $name,
	"                  Biography:                          ",
	"Status:             {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}", $bio,
	"  {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}", $status,
	"                    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}", 
	"Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}",
	"  {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}", $comments;
