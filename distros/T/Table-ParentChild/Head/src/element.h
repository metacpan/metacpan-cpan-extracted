typedef struct element_struct {
	double						value;
	struct head_struct *		head_parent;
	struct head_struct *		head_child;
	struct element_struct *		next_parent;
	struct element_struct *		next_child;

} element;


