import { createRoot } from 'react-dom/client'
import './index.css'
import { createInertiaApp } from '@inertiajs/react'

createInertiaApp({
  id: 'app',
  resolve: name => {
    const pages = import.meta.glob('./Pages/**/*.tsx', { eager: true })
    return pages[`./Pages/${name}.tsx`]
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />)
  },
})

