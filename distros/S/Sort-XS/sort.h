#ifndef _SORT_H
#define _SORT_H

/* typedef used */
typedef union {
	double f;
        IV     i;
	char  *s;
} ElementType;

typedef int (CmpFunction)(const ElementType *a, const ElementType *b);

/* prototype of functions */

int compare_int(const ElementType *a, const ElementType *b);
int compare_str(const ElementType *a, const ElementType *b);

void InsertionSort(ElementType A[], int N, CmpFunction *cmp);
void ShellSort(ElementType A[], int N, CmpFunction *cmp);
void HeapSort(ElementType A[], int N, CmpFunction *cmp);
void MergeSort(ElementType A[], int N, CmpFunction *cmp);
void QuickSort(ElementType A[], int N, CmpFunction *cmp);

/* used to benchmark memory usage */
void VoidSort(ElementType A[], int N, CmpFunction *cmp);

#endif
