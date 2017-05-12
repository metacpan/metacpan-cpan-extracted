#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <ctype.h>

typedef struct Suffix_Tree_Node Suffix_Tree_Node;

typedef struct Active_Point Active_Point;

struct Active_Point
{
  int m_node_id;
  int m_begin_idx;
  int m_end_idx;
};

struct Suffix_Tree_Node
{
  int m_begin_char_idx; /* inclusive */
  int m_end_char_idx;   /* inclusive */
  int m_parent;
  int m_id;
  int m_child;
  int m_sibling;
  int m_in_s1;
  int m_in_s2;
};

typedef struct Suffix_Tree Suffix_Tree;

struct Suffix_Tree
{
  Suffix_Tree_Node *m_nodes;
  int m_hash_base;
  int m_strlen;
  int m_size;
  char *m_str;
  int *m_suffix;
  Suffix_Tree_Node m_head;
};

static void ctor_node(Suffix_Tree_Node *node,
               int begin_idx, int end_idx, int parent, int id)
{
  node->m_begin_char_idx = begin_idx;
  node->m_end_char_idx = end_idx;
  node->m_parent = parent;
  node->m_id = id;
  node->m_child = -1;
  node->m_sibling = -1;
}

static void suffix_tree_cleanup(Suffix_Tree *t)
{
  free(t->m_nodes);
  free(t->m_suffix);
  t->m_hash_base = -1;
}

static void ctor_Active_Point(Active_Point *ap, int node_id,
                       int begin_idx, int end_idx)
{
  ap->m_node_id = node_id;
  ap->m_begin_idx = begin_idx;
  ap->m_end_idx = end_idx;
}

static int implicit(Active_Point *ap)
{
  return ap->m_begin_idx <= ap->m_end_idx;
}

/*
static int explicit(Active_Point *ap)
{
  return ap->m_begin_idx > ap->m_end_idx;
}
*/

static int hash(Suffix_Tree *t, int parent_id, int chr)
{
  int x = ((parent_id << 8) + chr) % t->m_hash_base;
  if (x < 0) {
    x += t->m_hash_base;
  }
  return x;
}

static int ap_span(Active_Point *ap)
{
  return ap->m_end_idx - ap->m_begin_idx;
}

static int edge_span(Suffix_Tree_Node *node)
{
  return node->m_end_char_idx - node->m_begin_char_idx;
}

static char ap_begin_char(Suffix_Tree *t, Active_Point *ap)
{
  return t->m_str[ap->m_begin_idx];
}

static char ap_end_char(Suffix_Tree *t, Active_Point *ap)
{
  return t->m_str[ap->m_end_idx];
}

static char ap_any_char(Suffix_Tree *t, Active_Point *ap, int any) 
{ 
  return t->m_str[ap->m_begin_idx + any]; 
}

static char node_begin_char(Suffix_Tree *t, Suffix_Tree_Node *node)
{
  return t->m_str[node->m_begin_char_idx];
}

static char node_end_char(Suffix_Tree *t, Suffix_Tree_Node *node)
{
  return t->m_str[node->m_end_char_idx];
}

static char node_any_char(Suffix_Tree *t, Suffix_Tree_Node *node, int any)
{
  return t->m_str[node->m_begin_char_idx + any];
}

static char node_contains(Suffix_Tree_Node *node, int pos)
{
  return node->m_begin_char_idx <= pos && pos <= node->m_end_char_idx;
}

/* find a node(edge) which is a child of 'parent_id' and begin with 'chr' */
static int find_unused_node(Suffix_Tree *t, int parent_id, int chr)
{
  int i = hash(t, parent_id, chr);
  while (1) {
    Suffix_Tree_Node *node = t->m_nodes + i;
    if (0 > node->m_id) {  /* unused slot */
      return i;
    }
    ++i;
    i = i % t->m_hash_base;
    if (i < 0) {
      i += t->m_hash_base;
    }
  }
}

/* find a node(edge) which is a child of 'parent_id' and begin with 'chr' */
static int find_node(Suffix_Tree *t, int parent_id, int chr)
{
  int i = hash(t, parent_id, chr);
  while (1) {
    Suffix_Tree_Node *node = t->m_nodes + i;
    if (-1 == node->m_id) {  /* unused slot */
      return i;
    }
    if (node->m_parent == parent_id &&
        node_begin_char(t, node) == chr) {
      return i;
    }
    /*    printf("%d \n", i); */
    ++i;
    i = i % t->m_hash_base;
    if (i < 0) {
      i += t->m_hash_base;
    }
  }
}

static void increment(int *i, int base)
{
  ++*i;
  *i = *i % base;
  if (*i < 0) {
    *i += base;
  }
}

static int new_node(Suffix_Tree *t, int begin_idx, int end_idx, int parent)
{
  int i;
  t->m_size++;
  i = find_unused_node(t, parent, t->m_str[begin_idx]);
  {
    Suffix_Tree_Node *node = t->m_nodes + i;
    assert (0 > node->m_id); /* unused or removed */
    ctor_node(node, begin_idx, end_idx, parent, t->m_size);
  }
  return i;
}

static int split_edge(Suffix_Tree *t, Active_Point *ap)
{
  int node_idx, i, nid;
  Suffix_Tree_Node *node, *tmp_node;
  assert(ap);
  assert(implicit(ap));
  node_idx = find_node(t, ap->m_node_id, ap_begin_char(t, ap));
  node = t->m_nodes + node_idx;

  assert(node->m_id != -1);
  assert(edge_span(node) >= ap_span(ap));

  assert(ap_span(ap) > 0);
  assert(ap_end_char(t, ap) != node_any_char(t, node, ap_span(ap)));
  assert(ap_any_char(t, ap, ap_span(ap)-1) == node_any_char(t, node, ap_span(ap)-1));

  /* match up to [ap_span(ap) - 1], see last two assertions
   * we want to reuse the existing node because parent and the first char
   * does not change, so what we create below is actually the existing node
   * We have to adjust the node "node"
   */
  i = new_node(t, node->m_begin_char_idx + ap_span(ap),
               node->m_end_char_idx,
               t->m_size+1);  /* parent is the newly created id */

  /* swap node id because the new node should be parent of the existing node. */
  tmp_node = t->m_nodes + i;
  tmp_node->m_id = node->m_id;

  node->m_id = t->m_size;
  node->m_end_char_idx = node->m_begin_char_idx + ap_span(ap) - 1;
  return t->m_size;
}

static void canonize(Suffix_Tree *t, Active_Point *ap)
{
  while (ap_span(ap) > 0) {
    int edge_len;
    int nid = find_node(t, ap->m_node_id, ap_begin_char(t, ap));
    Suffix_Tree_Node *node = t->m_nodes + nid;
    if ( node->m_id <= 0) {
      return;
    }
    edge_len = edge_span(node);
    if (edge_len > ap_span(ap) - 1) {
      return;
    }
    ap->m_node_id = node->m_id;
    ap->m_begin_idx += edge_len + 1;
  }
}

static void follow_suffix_link(Suffix_Tree *t, Active_Point *ap)
{
  if (ap->m_node_id) { /* not root */
    ap->m_node_id = t->m_suffix[ap->m_node_id];
  } else { /* root */
    ap->m_begin_idx++;
  }
  canonize(t, ap);
}

static void update(Suffix_Tree *t, Active_Point *ap)
{
  int last_parent = -1;
  while (1) {
    int node_idx = find_node(t, ap->m_node_id, ap_begin_char(t, ap));
    Suffix_Tree_Node *node = t->m_nodes + node_idx;
    assert(ap_span(ap) >= 0);

    if (node->m_id < 0) {
      assert(ap_span(ap) == 0);
      /* new node */
      new_node(t, ap->m_end_idx, t->m_strlen - 1, ap->m_node_id);
      if (last_parent > 0) {
        assert(t->m_suffix[last_parent] == ap->m_node_id
               || t->m_suffix[last_parent] == -1);
        t->m_suffix[last_parent] = ap->m_node_id;
      }
      last_parent = ap->m_node_id;
      follow_suffix_link(t, ap);
      if (ap_span(ap) < 0) break;
    } else {
      assert(edge_span(node) >= ap_span(ap) - 1);
      if (edge_span(node) == ap_span(ap) - 1) {
        
      }
      if (node_any_char(t, node, ap_span(ap)) == ap_end_char(t, ap)) { /* match */
        if (last_parent > 0) {
          /* suffix link: last_parent -> current's parent */
          t->m_suffix[last_parent] = node->m_parent;
        }
        break;
      } else { /* last char in active point not match */
        int parent;
        assert(ap_span(ap) > 0);
        assert(ap_any_char(t, ap, ap_span(ap) - 1) ==
               node_any_char(t, node, ap_span(ap) - 1));

        assert(implicit(ap));
        parent = split_edge(t, ap);

        new_node(t, ap->m_end_idx, t->m_strlen-1, parent);
        if (last_parent > 0) {
          assert(t->m_suffix[last_parent] == -1);
          t->m_suffix[last_parent] = parent;
        }
        last_parent = parent;
        follow_suffix_link(t, ap);
      }
    }
  }
}

static void print(Suffix_Tree *t)
{
  int i, j;
  for (i = 0; i < t->m_hash_base; i++) {
    Suffix_Tree_Node *node = t->m_nodes + i;
    if (node->m_id > 0) {
      printf("%4d%4d%4d%4d%4d  ", node->m_parent, node->m_id,
             node->m_begin_char_idx, node->m_end_char_idx, t->m_suffix[node->m_id]);
      for (j = node->m_begin_char_idx;
           j <= node->m_end_char_idx; j++) {
        printf("%c", t->m_str[j]);
      }
      printf("\n");
    }
  }
}

static void print_ap(Active_Point *ap)
{
  printf("%d  %d  %d\n", ap->m_node_id, ap->m_begin_idx, ap->m_end_idx);
}

static void suffix_tree_init(Suffix_Tree *t, char *str)
{
  int size = strlen(str) + 1;
  int i;
  t->m_strlen = size;
  size *= 2;
  t->m_hash_base = size+1;
  t->m_size = 0;
  t->m_nodes = (Suffix_Tree_Node*)
    malloc(sizeof(Suffix_Tree_Node)*t->m_hash_base);
  t->m_str = str;
  t->m_suffix = (int*)malloc(sizeof(int) * t->m_hash_base);

  for (i = 0; i < t->m_hash_base; i++) {
    ctor_node(t->m_nodes + i, -1, -1, -1, -1);
    t->m_suffix[i] = -1;
  }
  {
    Active_Point ap;
    ctor_Active_Point(&ap, 0, 0, 0);
    for (;ap.m_end_idx < t->m_strlen; ap.m_end_idx++) {
      canonize(t, &ap);
      update(t, &ap);
      /*      print(t);
            print_ap(&ap);
            printf("-----------------------------------------------\n\n");
	    */
    }
  }
}

static void suffix_tree_destroy(Suffix_Tree *t)
{
  free(t->m_nodes);
  free(t->m_suffix);
}

#define END_STRING 0
#define DOLLAR_SIGN -1

static void calc_lcs(Suffix_Tree *t, int s1_len, int id, int depth,
              int *len, int *pos1, int *pos2)
{
  Suffix_Tree_Node *node = t->m_nodes + id;
  assert(node->m_id == id && id >= 0);
  if (edge_span(node) >= 0 &&
      node_contains(node, s1_len)) {
    assert(-1 == node->m_child);
  } else if (edge_span(node) >= 0 &&
             node_end_char(t, node) == END_STRING) {
    assert(-1 == node->m_child);
  } else {
    int child = node->m_child;
    int t1, t2;
    /*    assert(node->m_child > 0); */

    while (child > 0) {
      Suffix_Tree_Node *nc = t->m_nodes + child;
      calc_lcs(t, s1_len, child, depth + edge_span(node) + 1, len, pos1, pos2);
      child = nc->m_sibling;
      if (nc->m_in_s1) {
        t1 = nc->m_begin_char_idx;
      }
      if (nc->m_in_s2) {
        t2 = nc->m_begin_char_idx;
      }
    }
    if (node->m_in_s1 && node->m_in_s2 && *len < depth + edge_span(node) + 1) {
      *len = depth + edge_span(node) + 1;
      *pos1 = t1;
      *pos2 = t2;
    }
  }
  assert(node->m_in_s1 || node->m_in_s2);
}

static void traverse_mark(Suffix_Tree *t, int s1_len, int id)
{
  Suffix_Tree_Node *node = t->m_nodes + id;
  assert(node->m_id == id && id >= 0);
  node->m_in_s1 = 0;
  node->m_in_s2 = 0;
  if (edge_span(node) >= 0 &&
      node_contains(node, s1_len)) {
    assert(-1 == node->m_child);
    node->m_in_s1 = 1;
  } else if (edge_span(node) >= 0 &&
             node_end_char(t, node) == END_STRING) {
    assert(-1 == node->m_child);
    node->m_in_s2 = 1;
  } else {
    int child = node->m_child;
    /*    assert(node->m_child > 0); */
    while (child > 0) {
      Suffix_Tree_Node *nc = t->m_nodes + child;
      traverse_mark(t, s1_len, child);
      child = nc->m_sibling;
      if (nc->m_in_s1) node->m_in_s1 = 1;
      if (nc->m_in_s2) node->m_in_s2 = 1;
    }
  }
  assert(node->m_in_s1 || node->m_in_s2);
}

static void lcs(int *pos1, int *pos2, int *len,
         char const *s1, int s1_len,
         char const *s2, int s2_len)
{
  char *buff =
    (char *)malloc(sizeof(const char) * (s1_len + s2_len + 2));
  Suffix_Tree t;
  strncpy((char*)buff, (char*)s1, s1_len);
  buff[s1_len] = DOLLAR_SIGN;  /* as '$' */
  strncpy(buff + s1_len + 1, s2, s2_len);
  buff[s1_len + s2_len + 1] = 0;
  suffix_tree_init(&t, buff);
  {
    /* construct child and sibling */
    int i;
    /* first move node to their proper destination based on their id */
    for (i = 0; i < t.m_hash_base; i++) {
      Suffix_Tree_Node *node = t.m_nodes + i;
      while (node->m_id > 0 && node->m_id != i) {
        Suffix_Tree_Node tmp = t.m_nodes[node->m_id];
        t.m_nodes[node->m_id] = *node;
        *node = tmp;
      }
    }
    
    /* set up root (node 0) */
    ctor_node(t.m_nodes, 0, -1, -1, 0);

    /* construct the tree */
    for (i = 1; i < t.m_hash_base; i++) {
      Suffix_Tree_Node *node = t.m_nodes + i;
      Suffix_Tree_Node *parent;
      if (node->m_id <= 0) {
        break;
      }
      parent = t.m_nodes + node->m_parent;
      node->m_sibling = parent->m_child;
      parent->m_child = node->m_id;
    }
    /* post order traversal */
    {
      traverse_mark(&t, s1_len, 0);
      calc_lcs(&t, s1_len, 0, 0, len, pos1, pos2);      
      if (*len > 0) {
        *pos1 -= *len;
        *pos2 -= s1_len + 1 + *len;
        assert(*pos1 >= 0);
        assert(*pos2 >= 0);
      }
    }
  }
  suffix_tree_destroy(&t);
  free(buff);
}

/* 1. count the number of lines ("\n").
 * 2. record the begin and end position of each line, ignoring
 *    leading and trailing white spaces, including "\n"
 * 3. 
 */
#define BEGIN_LINE 0

static void normalize(char **ostr, int **line_attrs, char *istr, int len)
{
  int i, num_lines = 0;
  int state = BEGIN_LINE;
  int trailing_ws = 0;
  char *tmp_str;

  tmp_str = *ostr = (char *)malloc(sizeof(char) * (len+1));
  for (i = 0; i < len; i++) {
    if ('\n' == istr[i]) num_lines++;
  }
  num_lines++;
  *line_attrs = (int*)malloc(sizeof(int) * (num_lines + 1));
  **line_attrs = num_lines;
  num_lines = 1;
  for (i = 0; i < len; i++) {
    if ('\n' == istr[i]) {
      tmp_str -= trailing_ws;
      (*line_attrs)[num_lines] = tmp_str - *ostr;
      num_lines++;
      trailing_ws = 0;
      state = BEGIN_LINE;
    } else {
      if (isspace(istr[i])) {
        if (BEGIN_LINE == state) continue;
        else {
          trailing_ws++;
        }
      } else if (BEGIN_LINE == state) {
        trailing_ws = 0;
        state = !BEGIN_LINE;
      } else {
        trailing_ws = 0;
      }
      *tmp_str = istr[i];
      tmp_str++;
    }
  }
  
  tmp_str -= trailing_ws;
  (*line_attrs)[num_lines] = tmp_str - *ostr;
  *tmp_str = 0;  /* terminate the string */
}

typedef struct equal_segment equal_segment;

struct equal_segment
{
  int m_begin1;
  int m_end1;
  int m_begin2;
  int m_end2;
  int m_begin_line_num1;
  int m_end_line_num1;
  int m_begin_line_num2;
  int m_end_line_num2;
  equal_segment *m_next;
};

static void equal_segment_ctor(equal_segment *seg,
                        int b1, int e1, int b2, int e2, equal_segment *next)
{
  seg->m_begin1 = b1;
  seg->m_end1 = e1;
  seg->m_begin2 = b2;
  seg->m_end2 = e2;
  seg->m_next = next;
  seg->m_begin_line_num1 = -1;
  seg->m_end_line_num1 = -1;
  seg->m_begin_line_num2 = -1;
  seg->m_end_line_num2 = -1;
}

static void diff(equal_segment **segs, char const *orig_s1,
          char const *s1, int len1,
          char const *orig_s2, char const *s2, int len2)
{
  int pos1, pos2, len = 0;
  equal_segment *tmp_seg;

  lcs(&pos1, &pos2, &len, s1, len1, s2, len2);

  if (len <= 3) {
    return;
  }
  
  /* traversal order: right, left, root */
  if (len1 - pos1 - len >= 4 && len2 - pos2 - len >= 4) {
    diff(segs, orig_s1, s1 + pos1 + len, len1 - pos1 - len,
         orig_s2, s2 + pos2 + len, len2 - pos2 - len);
  }
  tmp_seg = (equal_segment*)malloc(sizeof(equal_segment));
  equal_segment_ctor(tmp_seg, s1 - orig_s1 + pos1,
                     s1 - orig_s1 + pos1 + len,
                     s2 - orig_s2 + pos2,
                     s2 - orig_s2 + pos2 + len,
                     *segs);
  *segs = tmp_seg;
  if (pos1 >= 4 && pos2 >= 4) {
    diff(segs, orig_s1, s1, pos1, orig_s2, s2, pos2);
  }
}

static void adjust(equal_segment *equal_segs, const char *s1, const char *s2)
{
  int i, num_chars = 0;
  int state = BEGIN_LINE;
  int trailing_ws = 0;
  int tmp_begin;
  int line_num = 0, tmp_line_num;
  equal_segment *segs = equal_segs;

  for (i = 0; 0 == i || s1[i-1]; i++) {
    if (!segs) {
      break;
    }
    if (segs->m_begin1 == num_chars) {
      tmp_begin = i;
      tmp_line_num = line_num;
      while (tmp_begin > 0 && isspace(s1[tmp_begin-1])) {
        if ('\n' == s1[tmp_begin-1]) {
          tmp_line_num--;
        }
        tmp_begin--;
      }
    }
    if (segs->m_end1 <= num_chars && '\n' != s1[i]) {
      segs->m_begin1 = tmp_begin;
      segs->m_begin_line_num1 = tmp_line_num;
      segs->m_end1 = i;
      segs->m_end_line_num1 = line_num;
      while (s1[segs->m_end1] && isspace(s1[segs->m_end1])) {
        if ('\n' == s1[segs->m_end1]) {
          segs->m_end_line_num1++;
        }
        segs->m_end1++;
      }
      segs = segs->m_next;
      if (!segs) break;
      if (segs->m_begin1 == num_chars) {
        tmp_begin = i;
        tmp_line_num = line_num;
        while (tmp_begin > 0 && isspace(s1[tmp_begin-1])) {
          if ('\n' == s1[tmp_begin-1]) {
            tmp_line_num--;
          }
          tmp_begin--;
        }
      }
    }
    if ('\n' == s1[i]) {
      line_num++;
      num_chars -= trailing_ws;
      trailing_ws = 0;
      state = BEGIN_LINE;
    } else {
      if (isspace(s1[i])) {
        if (BEGIN_LINE == state) continue;
        else {
          while (isspace(s1[i]) && '\n' != s1[i]) {
            trailing_ws++;
            num_chars++;
            i++;
          }
          if (!isspace(s1[i]) || '\n' == s1[i]) i--;
          continue;
        }
      } else if (BEGIN_LINE == state) {
        trailing_ws = 0;
        state = !BEGIN_LINE;
      } else {
        trailing_ws = 0;
      }
      num_chars++;
    }
  }

  trailing_ws = 0;
  line_num = 0;
  num_chars = 0;
  segs = equal_segs;
  state = BEGIN_LINE;
  for (i = 0; 0==i || s2[i-1]; i++) {
    if (!segs) {
      break;
    }
    if (segs->m_begin2 == num_chars) {
      tmp_begin = i;
      tmp_line_num = line_num;
      while (tmp_begin > 0 && isspace(s2[tmp_begin-1])) {
        if ('\n' == s2[tmp_begin-1]) {
          tmp_line_num--;
        }
        tmp_begin--;
      }
    }
    if (segs->m_end2 <= num_chars && '\n' != s2[i]) {
      segs->m_begin2 = tmp_begin;
      segs->m_begin_line_num2 = tmp_line_num;
      segs->m_end2 = i;
      segs->m_end_line_num2 = line_num;
      while (s2[segs->m_end2] && isspace(s2[segs->m_end2])) {
        if ('\n' == s2[segs->m_end2]) {
          segs->m_end_line_num2++;
        }
        segs->m_end2++;
      }
      segs = segs->m_next;
      if (!segs) break;
      if (segs->m_begin2 == num_chars) {
        tmp_begin = i;
        tmp_line_num = line_num;
        while (tmp_begin > 0 && isspace(s2[tmp_begin-1])) {
          if ('\n' == s2[tmp_begin-1]) {
            tmp_line_num--;
          }
          tmp_begin--;
        }
      }
    }
    if ('\n' == s2[i]) {
      line_num++;
      num_chars -= trailing_ws;
/*       printf("white %d\n", trailing_ws); */
      trailing_ws = 0;
      state = BEGIN_LINE;
    } else {
      if (isspace(s2[i])) {
        if (BEGIN_LINE == state) continue;
        else {
          while (isspace(s2[i]) && '\n' != s2[i]) {
            trailing_ws++;
            num_chars++;
            i++;
          }
          if (!isspace(s2[i]) || '\n' == s2[i]) i--;
          continue;
        }
      } else if (BEGIN_LINE == state) {
        trailing_ws = 0;
        state = !BEGIN_LINE;
      } else {
        trailing_ws = 0;
      }
/*       printf("\"%c\"\n", s2[i]); */
      num_chars++;
    }
  }
}

char *ediff(char *s1, char *s2)
{
  int *line_attrs1, *line_attrs2, ix = 0;
  char *ostr1, *ostr2, *ret;
  /*    int pos1, pos2, len = 0; */
  equal_segment *equals = NULL, *tmp_seg;

  normalize(&ostr1, &line_attrs1, s1, strlen(s1));
  normalize(&ostr2, &line_attrs2, s2, strlen(s2));

  diff(&equals, ostr1, ostr1, strlen(ostr1), ostr2, ostr2, strlen(ostr2));
  /*    lcs(&pos1, &pos2, &len, ostr1, strlen(ostr1), ostr2, strlen(ostr2));
   */
  adjust(equals, s1, s2);
  tmp_seg = equals;
  while (tmp_seg) {
    ix++;
    tmp_seg = tmp_seg->m_next;
  }
#define INT_LEN 11
  ret = (char*)malloc(sizeof(char) * INT_LEN * ix * 8 + 1);
  ret[0] = 0;
  tmp_seg = equals;
  while (tmp_seg) {
    char buff[4 * INT_LEN + 1];
    if (tmp_seg->m_begin_line_num1 < 0) {
      tmp_seg->m_begin_line_num1 = line_attrs1[0];
    }
    if (tmp_seg->m_end_line_num1 < 0) {
      tmp_seg->m_end_line_num1 = line_attrs1[0];
    }
    if (tmp_seg->m_begin_line_num2 < 0) {
      tmp_seg->m_begin_line_num2 = line_attrs2[0];
    }
    if (tmp_seg->m_end_line_num2 < 0) {
      tmp_seg->m_end_line_num2 = line_attrs2[0];
    }
    sprintf(buff, "%d %d %d %d %d %d %d %d ",
            tmp_seg->m_begin1, tmp_seg->m_end1,
            tmp_seg->m_begin_line_num1, tmp_seg->m_end_line_num1,
            tmp_seg->m_begin2, tmp_seg->m_end2,
            tmp_seg->m_begin_line_num2, tmp_seg->m_end_line_num2);
    strcat(ret, buff);
    tmp_seg = tmp_seg->m_next;
  }

  tmp_seg = equals;
  while (tmp_seg) {
    equal_segment *next = tmp_seg->m_next;
    free(tmp_seg);
    tmp_seg = next;
  }
  free(ostr1); free(ostr2); free(line_attrs1); free(line_attrs2);
  return ret;
}

static void print_str(char *s, int len)
{
  int i;
  for (i = 0; i < len; i++) {
    printf("%c", s[i]);
  }
}
