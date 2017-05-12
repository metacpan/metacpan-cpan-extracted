typedef struct x {      
  char name[20];
  int age;
  struct x *next_rec;
} linklist;

/************************************************************************/

main()
{
  linklist *start_pointer;  /* Define pointers to the structure */
  linklist *next_pointer;

        /* Create some data to be placed in the
         * Linked list.       */
  char *names[]=
  {
    "Martin",
    "John  ",
    "Alex  ",
    ""
  };

  int ages[]={32, 43, 29, 0};

  int count=0;      /* General purpose counter.   */

   /*===================================================================*
    =                 =
    =   Build a LINKED LIST and place data into it.     =
    =                 =
    *===================================================================*/
       
        /* Initalise 'start_pointer' by reserving 
         * memory and pointing to it    */

  start_pointer=(linklist *) malloc (sizeof (linklist));

        /* Initalise 'next_pointer' to point
         * to the same location.    */
  next_pointer=start_pointer;

        /* Put some data into the reserved 
         * memory.        */

  strcpy(next_pointer->name, names[count]);
  next_pointer->age = ages[count];


        /* Loop until all data has been read  */

  while ( ages[++count] != 0 )
  {
        /* Reserve more memory and point to it  */

    next_pointer->next_rec=(linklist *) malloc (sizeof (linklist));

    next_pointer=next_pointer->next_rec;


    strcpy(next_pointer->name, names[count]);
    next_pointer->age = ages[count];
  }

  next_pointer->next_rec=NULL;

   /*===================================================================*
    =                 =
    =   Traverse the linked list and O/P all the data within it.  =
    =                 =
    *===================================================================*/


  next_pointer=start_pointer;

  while (next_pointer != NULL)
  {
    printf("%s   ", next_pointer->name);
    printf("%d \n", next_pointer->age);
    next_pointer=next_pointer->next_rec;
  }
}


