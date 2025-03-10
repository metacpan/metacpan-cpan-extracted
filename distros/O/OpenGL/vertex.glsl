uniform vec4 center;
uniform mat4 xform;

void main(void)
{
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
  gl_Position *= xform;

  // Calc texcoord values
  vec4 pos = gl_Vertex;
  float d = sqrt(pos.x * pos.x + pos.y * pos.y);
  float a = atan(pos.x/pos.y) / 3.1415;
  if (a < 0.0) a += 1.0;
  a *= 2.0;
  a -= float(int(a));

  pos -= center;
  float h = pos.z;
  h = abs(2.0 * atan(h/d) / 3.1415);

  gl_TexCoord[0].x = a;
  gl_TexCoord[0].y = h;
} 
