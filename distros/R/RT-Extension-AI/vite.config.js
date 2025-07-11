import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  server: {
    open: 'src/index.html',
  },
  build: {
    outDir: 'static/js',
    cssCodeSplit: true,
    lib: {
      entry: resolve(__dirname, 'src/index.js'),
      name: 'RtExtensionAi',
      formats: ['umd'],
      fileName: () => 'rt-extension-ai.js',
    }
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
});
